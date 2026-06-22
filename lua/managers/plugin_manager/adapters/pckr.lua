local M = {}

M.install_dir = vim.fn.stdpath("data") .. "/site/pack/pckr"

local generic_fields = {
  url = true, trigger = true, load = true,
  category = true, optional = true, metadata = true,
  condition = true, enabled = true, priority = true,
}

-- lazily require pckr loaders so they work even if pckr isn't on rtp yet
local function event_cond(events)
  return function(load_plugin)
    local group = vim.api.nvim_create_augroup("PckrEvent", { clear = false })
    vim.api.nvim_create_autocmd(type(events) == "table" and events or { events }, {
      group = group,
      once = true,
      callback = function() load_plugin() end,
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
      callback = function() load_plugin() end,
    })
  end
end

local function lazy_cond()
  return function(load_plugin)
    vim.api.nvim_create_autocmd("VimEnter", {
      once = true,
      callback = function()
        load_plugin()
        return true
      end,
    })
  end
end

local function require_cond(modules)
  return function(load_plugin)
    local mods = type(modules) == "table" and modules or { modules }
    local _require = _G.require
    _G.require = function(name)
      for _, mod in ipairs(mods) do
        if name:find("^" .. mod:gsub("%.", "%%.")) then
          _G.require = _require
          load_plugin()
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
          load_plugin()
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
            load_plugin()
            -- replay the command after plugin loads
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

  -- Normalize load abstraction into trigger
  if spec.load then
    spec.trigger = spec.trigger or {}
    local m = spec.load.mode
    if m == "startup" then
      spec.trigger.startup = true
    elseif m == "lazy" then
      spec.trigger.lazy = true
    elseif m == "event" then
      spec.trigger.event = spec.load.event
    elseif m == "cmd" then
      spec.trigger.cmd = spec.load.cmd
    elseif m == "keymap" then
      spec.trigger.keymap = spec.load.keymap
    elseif m == "require" then
      spec.trigger.require = spec.load.require
    elseif m == "ft" then
      spec.trigger.ft = spec.load.ft
    end
  end

  if spec.trigger then
    local t = spec.trigger
    is_startup = t.startup or false

    if t.lazy then
      table.insert(conds, lazy_cond())
    end

    if t.event then
      table.insert(conds, event_cond(t.event))
    end

    if t.cmd then
      local ok, builtin = pcall(require, "pckr.loader.cmd")
      if ok then
        for _, c in ipairs(type(t.cmd) == "table" and t.cmd or { t.cmd }) do
          if type(c) == "string" then
            table.insert(conds, builtin(c))
          end
        end
      else
        table.insert(conds, cmd_cond(t.cmd))
      end
    end

    if t.keymap then
      local ok, builtin = pcall(require, "pckr.loader.keys")
      if ok then
        local items = type(t.keymap) == "table" and t.keymap or { t.keymap }
        for _, km in ipairs(items) do
          if type(km) == "table" then
            local mode = km.mode or "n"
            local lhs = km[1]
            if lhs then
              table.insert(conds, builtin(mode, lhs))
            end
          elseif type(km) == "string" then
            table.insert(conds, builtin("n", km))
          end
        end
      else
        table.insert(conds, keymap_cond(t.keymap))
      end
    end

    if t.require then
      table.insert(conds, require_cond(t.require))
    end

    if t.ft then
      table.insert(conds, ft_cond(t.ft))
    end
  end

  -- pckr auto-loads plugins with config but no triggers at startup (goes in start/).
  -- Explicitly add lazy cond so config-only plugins stay lazy.
  if #conds == 0 and not is_startup and spec.config then
    table.insert(conds, lazy_cond())
  end

  if #conds > 0 then
    if #conds == 1 then
      result.cond = conds[1]
    else
      result.cond = conds
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
  end

  for k, v in pairs(spec) do
    if not generic_fields[k] and result[k] == nil then
      result[k] = v
    end
  end

  return result
end

function M.translate_all(specs)
  local pckr_specs = {}
  for _, spec in ipairs(specs) do
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

function M.plugin_path(url)
  local dir_name = url:match("[^/]+$")
  if not dir_name then
    return nil
  end
  local opt_path = M.install_dir .. "/opt/" .. dir_name
  if vim.uv.fs_stat(opt_path) then
    return opt_path
  end
  local start_path = M.install_dir .. "/start/" .. dir_name
  if vim.uv.fs_stat(start_path) then
    return start_path
  end
  return opt_path
end

local pckr_base = vim.fn.stdpath("data") .. "/pckr"

function M.bootstrap(specs, opts)
  opts = opts or {}
  local pckr_opts = opts.pckr_opts or {}

  local pckr_path = pckr_base .. "/pckr.nvim"
  if not (vim.uv or vim.loop).fs_stat(pckr_path) then
    local repo = "https://github.com/lewis6991/pckr.nvim"
    local out = vim.fn.system({ "git", "clone", "--filter=blob:none", repo, pckr_path })
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

  vim.opt.rtp:prepend(pckr_path)

  if next(pckr_opts) then
    pcall(require("pckr").setup, pckr_opts)
  end

  local pckr_specs = M.translate_all(specs)
  require("pckr").add(pckr_specs)
end

return M
