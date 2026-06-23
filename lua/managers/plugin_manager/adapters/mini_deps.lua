local M = {}

local generic_fields = {
  url = true, trigger = true, load = true,
  category = true, optional = true, metadata = true,
  enabled = true,
}

local _spec_data = {}
local _loading = {}
local _loaded = {}

local function _load(fn)
  local ok, err = pcall(fn)
  if not ok then
    vim.api.nvim_echo({{ "[mini.deps] Error: " .. tostring(err):sub(1, 200), "WarningMsg" }}, false, {})
  end
end

local function event_cond(events, name)
  return function()
    local group = vim.api.nvim_create_augroup("MiniDepsEvent", { clear = false })
    vim.api.nvim_create_autocmd(type(events) == "table" and events or { events }, {
      group = group,
      once = true,
      callback = function() _load(function() M.load_plugin(name) end) end,
    })
  end
end

local function ft_cond(fts, name)
  return function()
    local group = vim.api.nvim_create_augroup("MiniDepsFt", { clear = false })
    vim.api.nvim_create_autocmd("FileType", {
      group = group,
      once = true,
      pattern = fts,
      callback = function() _load(function() M.load_plugin(name) end) end,
    })
  end
end

local function lazy_cond(name)
  return function()
    vim.api.nvim_create_autocmd("VimEnter", {
      once = true,
      callback = function()
        local ok, err = pcall(M.load_plugin, name)
        if not ok then
          vim.api.nvim_echo({{ "[mini.deps] Error: " .. tostring(err):sub(1, 200), "WarningMsg" }}, false, {})
        end
        return true
      end,
    })
  end
end

local function require_cond(modules, name)
  local mods = type(modules) == "table" and modules or { modules }
  return function()
    local _require = _G.require
    _G.require = function(n)
      for _, mod in ipairs(mods) do
        if n:find("^" .. mod:gsub("%.", "%%.")) then
          _load(function() M.load_plugin(name) end)
          break
        end
      end
      return _require(n)
    end
  end
end

local function keymap_cond(keymaps, name)
  return function()
    local items = type(keymaps) == "table" and keymaps or { keymaps }
    for _, km in ipairs(items) do
      if type(km) == "table" then
        local lhs = km[1]
        local rhs = km[2]
        local mode = km.mode or "n"
        local opts = { desc = km.desc or "MiniDeps" }
        vim.keymap.set(mode, lhs, function()
          _load(function() M.load_plugin(name) end)
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

local function cmd_cond(commands, name)
  return function()
    local cmds = type(commands) == "table" and commands or { commands }
    for _, c in ipairs(cmds) do
      if type(c) == "string" then
        local cmd_name = c:match("^[%w_]+")
        if cmd_name then
          vim.api.nvim_create_user_command(cmd_name, function(info)
            _load(function() M.load_plugin(name) end)
            vim.cmd(c .. " " .. (info.args or ""))
          end, {
            nargs = "*",
            desc = "MiniDeps lazy: " .. c,
          })
        end
      end
    end
  end
end

local function register_conds(name, trigger)
  local conds = {}

  if trigger.lazy then
    table.insert(conds, lazy_cond(name))
  end

  if trigger.event then
    table.insert(conds, event_cond(trigger.event, name))
  end

  if trigger.cmd then
    table.insert(conds, cmd_cond(trigger.cmd, name))
  end

  if trigger.keymap then
    table.insert(conds, keymap_cond(trigger.keymap, name))
  end

  if trigger.require then
    table.insert(conds, require_cond(trigger.require, name))
  end

  if trigger.ft then
    table.insert(conds, ft_cond(trigger.ft, name))
  end

  -- Lazy fallback for manual-only triggers (require, cmd, keymap)
  local has_auto = trigger.lazy or trigger.event or trigger.ft
  if not has_auto and #conds > 0 then
    table.insert(conds, 1, lazy_cond(name))
  end

  for _, cond in ipairs(conds) do
    cond()
  end
end

local function run_config(name, spec_data)
  if spec_data.init then
    local ok, err = pcall(spec_data.init)
    if not ok then
      vim.api.nvim_echo({{ "[mini.deps] init error for " .. name .. ": " .. tostring(err):sub(1, 200), "WarningMsg" }}, false, {})
    end
  end

  if spec_data.config then
    local ok, err = pcall(spec_data.config)
    if not ok then
      vim.api.nvim_echo({{ "[mini.deps] config error for " .. name .. ": " .. tostring(err):sub(1, 200), "WarningMsg" }}, false, {})
    end
  elseif spec_data.opts then
    local mod = spec_data.url and (spec_data.url:match("/(.+)%.nvim$") or spec_data.url:match("[^/]+$"))
    if mod then
      mod = mod:gsub("%.nvim$", "")
      local ok, p = pcall(require, mod)
      if ok and type(p.setup) == "function" then
        pcall(p.setup, spec_data.opts)
      end
    end
  end
end

local function run_build(name, build)
  if type(build) == "function" then
    local ok, err = pcall(build)
    if not ok then
      vim.api.nvim_echo({{ "[mini.deps] build error for " .. name .. ": " .. tostring(err):sub(1, 200), "WarningMsg" }}, false, {})
    end
  elseif type(build) == "string" then
    if build:match("^:") then
      vim.cmd(build:sub(2))
    else
      local spec_url = _spec_data[name] and _spec_data[name].url
      local path = spec_url and M.plugin_path(spec_url)
      if path and vim.uv.fs_stat(path) then
        vim.fn.system("cd " .. vim.fn.shellescape(path) .. " && " .. build)
      else
        vim.fn.system(build)
      end
    end
  end
end

function M.load_plugin(name)
  if _loaded[name] or _loading[name] then return end
  _loading[name] = true

  local ok, err = pcall(function()
    local data = _spec_data[name]
    if data then
      -- Gate on condition function if present
      if data.condition and not data.condition() then
        _loading[name] = nil
        return
      end

      local path = M.plugin_path(data.url)
      if path then
        vim.opt.rtp:prepend(path)
      end

      -- Run build BEFORE packadd — some plugins (blink.cmp) call require() in
      -- their plugin/ file, which crashes if the native lib isn't built yet.
      if data.build and not data._build_done then
        run_build(name, data.build)
        data._build_done = true
      end

      local spec = { source = data.url }

      if data.mini_depends then
        spec.depends = data.mini_depends
      end

      if data.checkout then
        spec.checkout = data.checkout
      end

      MiniDeps.add(spec)

      run_config(name, data)
    end
  end)

  _loading[name] = nil
  if ok then _loaded[name] = true end

  if not ok then
    vim.api.nvim_echo({{ "[mini.deps] load_plugin(" .. name .. "): " .. tostring(err):sub(1, 200), "WarningMsg" }}, false, {})
  end
end

function M.plugin_path(url)
  local dir_name = url:match("[^/]+$")
  if not dir_name then
    return nil
  end
  return vim.fn.stdpath("data") .. "/site/pack/deps/opt/" .. dir_name
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

function M.translate(spec)
  if not spec.url then
    return spec
  end

  local name = spec.name or spec.url:match("[^/]+$")

  local result = {
    source = "https://github.com/" .. spec.url,
    name = name,
  }

  -- Convert version field to checkout (supports semver ranges, tags, branches)
  if spec.version then
    if type(spec.version) == "string" then
      local v = spec.version:match("^([^*x]+)")
      if v then
        result.checkout = v
      else
        local ok, r = pcall(vim.version.range, spec.version)
        if ok then
          local coerced = tostring(r):match(">= ([%d%.]+)")
          if coerced then
            result.checkout = "v" .. coerced
          end
        end
      end
    end
  end

  local mini_depends
  if spec.dependencies then
    mini_depends = spec.dependencies
    result.depends = spec.dependencies
  end

  -- Convert build to post_checkout and post_install hooks
  if spec.build then
    local build_capture = spec.build
    result.hooks = result.hooks or {}
    result.hooks.post_checkout = function()
      run_build(name, build_capture)
    end
    result.hooks.post_install = function()
      run_build(name, build_capture)
    end
  end

  _spec_data[name] = {
    config = spec.config,
    init = spec.init,
    opts = spec.opts,
    build = spec.build,
    url = spec.url,
    condition = spec.condition,
    mini_depends = mini_depends,
    checkout = result.checkout,
  }

  return result
end

function M.translate_all(specs)
  local result = {}
  for _, spec in ipairs(specs) do
    table.insert(result, M.translate(spec))
  end
  return result
end

local function deps_path(name)
  return vim.fn.stdpath("data") .. "/site/pack/deps/opt/" .. name
end

function M.bootstrap(specs, opts)
  opts = opts or {}

  -- Disable conflicting pack directories from other adapters
  local site_pack = vim.fn.stdpath("data") .. "/site/pack"
  local data_dir = vim.fn.stdpath("data")
  local ok, entries = pcall(vim.fn.readdir, site_pack)
  if ok then
    for _, dir in ipairs(entries) do
      if dir ~= "deps" and vim.uv.fs_stat(site_pack .. "/" .. dir .. "/opt") then
        vim.uv.fs_rename(site_pack .. "/" .. dir, data_dir .. "/" .. dir .. ".disabled")
      end
    end
  end

  -- Install mini.nvim (which provides mini.deps) if not present
  local mini_path = deps_path("mini.nvim")
  if not vim.uv.fs_stat(mini_path) then
    vim.api.nvim_echo({{ "[mini.deps] Installing mini.nvim...", "Info" }}, false, {})
    local out = vim.fn.system({
      "git", "clone", "--depth=1", "--filter=blob:none",
      "https://github.com/echasnovski/mini.nvim", mini_path,
    })
    if vim.v.shell_error ~= 0 then
      vim.api.nvim_echo({{ "[mini.deps] Failed to clone mini.nvim: " .. (out or ""), "ErrorMsg" }}, true, {})
      return
    end
  end

  -- Add mini.nvim to rtp and require mini.deps
  vim.opt.rtp:prepend(mini_path)
  local mini_deps_opts = opts.mini_deps_opts or {}
  require("mini.deps").setup(mini_deps_opts)

  -- Restore from snapshot if available for version pinning
  local snapshot_path = vim.fn.stdpath("state") .. "/mini_deps_snapshot"
  if vim.uv.fs_stat(snapshot_path) then
    pcall(MiniDeps.restore, snapshot_path)
  end

  local translated = M.translate_all(specs)

  -- Install ALL plugins upfront, including deferred; run builds after clone
  for i, spec in ipairs(specs) do
    local name = spec.name or spec.url:match("[^/]+$")
    local install_path = deps_path(name)
    if not vim.uv.fs_stat(install_path) then
      local out = vim.fn.system({
        "git", "clone", "--depth=1", "--filter=blob:none",
        "https://github.com/" .. spec.url, install_path,
      })
      if vim.v.shell_error ~= 0 then
        vim.api.nvim_echo({{ "[mini.deps] clone failed for " .. spec.url .. ": " .. (out or ""), "ErrorMsg" }}, true, {})
      end
    end
  end

  local add_startup = {}
  local add_deferred = {}

  for i, spec in ipairs(specs) do
    local trigger = spec.trigger or {}
    local has_triggers = next(trigger)
    if has_triggers and not trigger.startup then
      table.insert(add_deferred, { spec = spec, translated = translated[i] })
    else
      table.insert(add_startup, { spec = spec, translated = translated[i] })
    end
  end

  -- Sort startup plugins by priority (higher = first)
  table.sort(add_startup, function(a, b)
    local pa = a.spec and a.spec.priority or 50
    local pb = b.spec and b.spec.priority or 50
    return pa > pb
  end)

  -- Load startup plugins through load_plugin (MiniDeps.add + run_config + build)
  for _, entry in ipairs(add_startup) do
    local name = entry.spec.name or entry.spec.url:match("[^/]+$")
    _load(function() M.load_plugin(name) end)
  end

  -- Register cond functions for deferred plugins
  for _, entry in ipairs(add_deferred) do
    local spec = entry.spec
    local trigger = spec.trigger or {}
    local name = spec.name or spec.url:match("[^/]+$")
    register_conds(name, trigger)
  end

  -- Save snapshot for future restoration
  pcall(MiniDeps.snapshot, snapshot_path)
end

return M
