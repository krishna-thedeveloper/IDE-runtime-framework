local M = {}

local generic_fields = {
  url = true, trigger = true, load = true,
  category = true, optional = true, metadata = true,
  enabled = true,
}

local function _load(fn)
  local ok, err = pcall(fn)
  if not ok then
    vim.api.nvim_echo({{ "[pckr] Error: " .. tostring(err):sub(1, 200), "WarningMsg" }}, false, {})
  end
end

local function event_cond(events)
  return function(load_plugin)
    local group = vim.api.nvim_create_augroup("PckrEvent", { clear = false })
    vim.api.nvim_create_autocmd(type(events) == "table" and events or { events }, {
      group = group,
      once = true,
      callback = function() _load(load_plugin) end,
    })
  end
end

local function ft_cond(fts)
  return function(load_plugin)
    local group = vim.api.nvim_create_augroup("PckrFt", { clear = false })
    vim.api.nvim_create_autocmd("FileType", {
      group = group,
      once = true,
      pattern = fts,
      callback = function() _load(load_plugin) end,
    })
  end
end

local function lazy_cond()
  return function(load_plugin)
    vim.schedule(function() _load(load_plugin) end)
    vim.api.nvim_create_autocmd("VimEnter", {
      once = true,
      callback = function()
        local ok, err = pcall(load_plugin)
        if not ok then
          vim.api.nvim_echo({{ "[pckr] Error: " .. tostring(err):sub(1, 200), "WarningMsg" }}, false, {})
        end
        return true
      end,
    })
  end
end

local function require_cond(modules)
  local mods = type(modules) == "table" and modules or { modules }
  return function(load_plugin)
    local _require = _G.require
    _G.require = function(name)
      for _, mod in ipairs(mods) do
        if name:find("^" .. mod:gsub("%.", "%%.")) then
          _load(load_plugin)
          break
        end
      end
      return _require(name)
    end
  end
end

local function keymap_cond(keymaps)
  return function(load_plugin)
    local items = type(keymaps) == "table" and keymaps or { keymaps }
    for _, km in ipairs(items) do
      if type(km) == "table" then
        local lhs = km[1]
        local rhs = km[2]
        local mode = km.mode or "n"
        local opts = { desc = km.desc or "Pckr" }
        vim.keymap.set(mode, lhs, function()
          _load(load_plugin)
          if type(rhs) == "function" then
            rhs()
          elseif rhs then
            vim.cmd(rhs)
          else
            local keys = vim.api.nvim_replace_termcodes(lhs, true, false, true)
            vim.api.nvim_feedkeys(keys, "m", true)
          end
        end, opts)
      end
    end
  end
end

local function cmd_cond(commands)
  return function(load_plugin)
    local cmds = type(commands) == "table" and commands or { commands }
    for _, c in ipairs(cmds) do
      if type(c) == "string" then
        local cmd_name = c:match("^[%w_]+")
        if cmd_name then
          vim.api.nvim_create_user_command(cmd_name, function(info)
            _load(load_plugin)
            vim.cmd(c .. " " .. (info.args or ""))
          end, {
            nargs = "*",
            desc = "Pckr lazy: " .. c,
          })
        end
      end
    end
  end
end

function M.translate(spec)
  if not spec.url then
    return spec
  end

  local result = { spec.url }
  local conds = {}
  local is_startup = false
  local trigger = spec.trigger

  -- Normalize load abstraction into trigger
  if spec.load then
    trigger = trigger or {}
    local m = spec.load.mode
    if m == "startup" then
      trigger.startup = true
    elseif m == "lazy" then
      trigger.lazy = true
    elseif m == "event" then
      trigger.event = spec.load.event
    elseif m == "cmd" then
      trigger.cmd = spec.load.cmd
    elseif m == "keymap" then
      trigger.keymap = spec.load.keymap
    elseif m == "require" then
      trigger.require = spec.load.require
    elseif m == "ft" then
      trigger.ft = spec.load.ft
    end
    spec.trigger = trigger
  end

  if trigger then
    is_startup = trigger.startup or false

    if trigger.lazy then
      table.insert(conds, lazy_cond())
    end

    if trigger.event then
      table.insert(conds, event_cond(trigger.event))
    end

    if trigger.cmd then
      table.insert(conds, cmd_cond(trigger.cmd))
    end

    if trigger.keymap then
      table.insert(conds, keymap_cond(trigger.keymap))
    end

    if trigger.require then
      table.insert(conds, require_cond(trigger.require))
    end

    if trigger.ft then
      table.insert(conds, ft_cond(trigger.ft))
    end
  end

  -- Add lazy fallback for plugins with manual-only triggers (require, cmd, keymap)
  -- so they eventually auto-load after startup even if never explicitly triggered.
  local has_auto = trigger and (trigger.lazy or trigger.event or trigger.ft or trigger.startup)
  if not is_startup and not has_auto and (spec.config or spec.init or #conds > 0) then
    table.insert(conds, 1, lazy_cond())
  end

  if #conds > 0 then
    if #conds == 1 then
      result.cond = conds[1]
    else
      result.cond = conds
    end
  end

  -- Also pass trigger fields natively supported by pckr.nvim so it can
  -- manage its own lazy-loading alongside the hand-rolled cond functions.
  if trigger then
    if trigger.event then result.event = trigger.event end
    if trigger.cmd then result.cmd = trigger.cmd end
    if trigger.keymap then result.keys = trigger.keymap end
    if trigger.ft then result.ft = trigger.ft end
    if trigger.require then result.module = trigger.require end
  end

  -- Wrap condition function around existing conds as a gate.
  -- pckr's cond(load_plugin) already wraps load_plugin; condition()
  -- is a boolean predicate that gates whether the load should proceed.
  if spec.condition then
    local existing = result.cond
    if existing then
      if type(existing) == "table" then
        local wrapped = {}
        for _, c in ipairs(existing) do
          table.insert(wrapped, function(load_plugin)
            if spec.condition() then c(load_plugin) end
          end)
        end
        result.cond = wrapped
      else
        local single = existing
        result.cond = function(load_plugin)
          if spec.condition() then single(load_plugin) end
        end
      end
    else
      result.cond = function(load_plugin)
        if spec.condition() then load_plugin() end
      end
    end
  end

  if spec.dependencies then
    result.requires = spec.dependencies
  end

  if spec.build then
    result.run = spec.build
  end

  if spec.init then
    result.config_pre = spec.init
  end

  if spec.config then
    result.config = spec.config
  elseif spec.opts then
    local mod = spec.url:match("/(.+)%.nvim$") or spec.url:match("[^/]+$")
    if mod and mod:match("%.nvim$") then
      mod = mod:gsub("%.nvim$", "")
    end
    if mod then
      local m = mod
      result.config = function()
        local ok, p = pcall(require, m)
        if ok and p.setup then
          p.setup(spec.opts)
        end
      end
    end
  end

  for k, v in pairs(spec) do
    if not generic_fields[k] and result[k] == nil then
      result[k] = v
    end
  end

  return result
end

function M.translate_all(specs)
  local seen = {}
  local merged = {}
  for _, spec in ipairs(specs) do
    if spec.url and seen[spec.url] then
      local existing = seen[spec.url]
      if spec.opts then
        existing.opts = existing.opts and vim.tbl_deep_extend("force", existing.opts, spec.opts) or spec.opts
      end
    else
      seen[spec.url] = spec
      table.insert(merged, spec)
    end
  end

  local pckr_specs = {}
  for _, spec in ipairs(merged) do
    table.insert(pckr_specs, M.translate(spec))
  end
  return pckr_specs
end

function M.load_plugin(name)
  vim.cmd("packadd " .. name)
end

function M.cleanup(name)
  local prefix = name:match("^([^.]+)")
  if prefix then
    for k in pairs(package.loaded) do
      if type(k) == "string" and k:find("^" .. prefix:gsub("[^%w_]", "%%%1")) then
        package.loaded[k] = nil
      end
    end
  end
end

-- pckr stores plugins at <pack_dir>/pack/pckr/{opt,start}/<name>.
-- Default pack_dir is stdpath("data")/site, so Neovim's built-in packadd
-- finds them via packpath.
function M.plugin_path(url)
  local dir_name = url:match("[^/]+$")
  if not dir_name then
    return nil
  end
  local base = vim.fn.stdpath("data") .. "/site/pack/pckr"
  local opt_path = base .. "/opt/" .. dir_name
  if vim.uv.fs_stat(opt_path) then
    return opt_path
  end
  local start_path = base .. "/start/" .. dir_name
  if vim.uv.fs_stat(start_path) then
    return start_path
  end
  return opt_path
end

local function pckr_path()
  return vim.fn.stdpath("data") .. "/pckr/pckr.nvim"
end

function M.bootstrap(specs, opts)
  opts = opts or {}

  local path = pckr_path()
  if not (vim.uv or vim.loop).fs_stat(path) then
    local repo = "https://github.com/lewis6991/pckr.nvim"
    local out = vim.fn.system({ "git", "clone", "--filter=blob:none", repo, path })
    if vim.v.shell_error ~= 0 then
      vim.api.nvim_echo({
        { "Failed to clone pckr.nvim:\n", "ErrorMsg" },
        { out, "WarningMsg" },
        { "\nPress any key to exit..." },
      }, true, {})
      vim.fn.getchar()
      os.exit(1)
    end
  end

  vim.opt.rtp:prepend(path)

  local pckr_opts = opts.pckr_opts or {}
  pcall(require("pckr").setup, pckr_opts)

  local pckr_specs = M.translate_all(specs)
  require("pckr").add(pckr_specs)
end

return M
