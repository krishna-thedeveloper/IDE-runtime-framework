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
    vim.api.nvim_echo({{ "[vim.pack] Error: " .. tostring(err):sub(1, 200), "WarningMsg" }}, false, {})
  end
end

local function event_cond(events, name)
  return function()
    local group = vim.api.nvim_create_augroup("VimPackEvent", { clear = false })
    vim.api.nvim_create_autocmd(type(events) == "table" and events or { events }, {
      group = group,
      once = true,
      callback = function() _load(function() M.load_plugin(name) end) end,
    })
  end
end

local function ft_cond(fts, name)
  return function()
    local group = vim.api.nvim_create_augroup("VimPackFt", { clear = false })
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
          vim.api.nvim_echo({{ "[vim.pack] Error: " .. tostring(err):sub(1, 200), "WarningMsg" }}, false, {})
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
        local opts = { desc = km.desc or "VimPack" }
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
            desc = "VimPack lazy: " .. c,
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

local function convert_version(spec)
  if not spec.version then
    return nil
  end
  if type(spec.version) == "string" then
    if spec.version:match("[*x]") then
      local ok, r = pcall(vim.version.range, spec.version)
      if ok then return r end
    end
    return spec.version
  end
  return spec.version
end

local function run_config(name, spec_data)
  if spec_data.init then
    local ok, err = pcall(spec_data.init)
    if not ok then
      vim.api.nvim_echo({{ "[vim.pack] init error for " .. name .. ": " .. tostring(err):sub(1, 200), "WarningMsg" }}, false, {})
    end
  end

  if spec_data.config then
    local ok, err = pcall(spec_data.config)
    if not ok then
      vim.api.nvim_echo({{ "[vim.pack] config error for " .. name .. ": " .. tostring(err):sub(1, 200), "WarningMsg" }}, false, {})
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
      vim.api.nvim_echo({{ "[vim.pack] build error for " .. name .. ": " .. tostring(err):sub(1, 200), "WarningMsg" }}, false, {})
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

local function core_path(name)
  return vim.fn.stdpath("data") .. "/site/pack/core/opt/" .. name
end

local function try_source(f)
  local ok, err = pcall(vim.cmd, "source " .. vim.fn.fnameescape(f))
  if not ok then
    vim.api.nvim_echo({{ "[vim.pack] " .. f .. ": " .. tostring(err):sub(1, 150), "WarningMsg" }}, false, {})
  end
end

local function source_plugin_files(path)
  if not vim.uv.fs_stat(path) then return end
  for _, pattern in ipairs({ "plugin/**/*.vim", "plugin/**/*.lua" }) do
    local files = vim.fn.globpath(path, pattern, false, true)
    table.sort(files)
    for _, f in ipairs(files) do
      try_source(f)
    end
  end
end

function M.add_to_rtp(name)
  local path = core_path(name)
  if not vim.uv.fs_stat(path) then return end
  local rtp = vim.opt.rtp:get()
  for _, dir in ipairs(rtp) do
    if dir == path then return end
  end
  vim.opt.rtp:prepend(path)
end

function M.load_plugin(name)
  if _loaded[name] or _loading[name] then return end
  _loading[name] = true

  local ok, err = pcall(function()
    local data = _spec_data[name]
    -- Gate on condition function if present
    if data and data.condition and not data.condition() then
      _loading[name] = nil
      return
    end

    M.add_to_rtp(name)
    -- For deferred plugins loaded after startup's runtime! step, source
    -- plugin files now.  Startup plugins rely on the built-in runtime! step.
    local p = core_path(name)
    source_plugin_files(p)
    source_plugin_files(p .. "/after")
    if data then
      run_config(name, data)
      if data.build and not vim.g["vim_pack_built_" .. name] then
        vim.g["vim_pack_built_" .. name] = true
        run_build(name, data.build)
      end
    end
  end)

  _loading[name] = nil
  if ok then _loaded[name] = true end

  if not ok then
    vim.api.nvim_echo({{ "[vim.pack] load_plugin(" .. name .. "): " .. tostring(err):sub(1, 200), "WarningMsg" }}, false, {})
  end
end

function M.plugin_path(url)
  local dir_name = url:match("[^/]+$")
  if not dir_name then
    return nil
  end
  return vim.fn.stdpath("data") .. "/site/pack/core/opt/" .. dir_name
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
    src = "https://github.com/" .. spec.url,
    name = name,
  }

  local ver = convert_version(spec)
  if ver then
    result.version = ver
  end

  _spec_data[name] = {
    config = spec.config,
    init = spec.init,
    opts = spec.opts,
    build = spec.build,
    url = spec.url,
    condition = spec.condition,
    dependencies = spec.dependencies,
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

function M.bootstrap(specs, opts)
  opts = opts or {}

  -- Move conflicting pack directories from other adapters outside packpath
  -- scope, so vim.pack does not double-source plugin files from both dirs.
  local site_pack = vim.fn.stdpath("data") .. "/site/pack"
  local data_dir = vim.fn.stdpath("data")
  local ok, entries = pcall(vim.fn.readdir, site_pack)
  if ok then
    for _, dir in ipairs(entries) do
      if dir ~= "core" and vim.uv.fs_stat(site_pack .. "/" .. dir .. "/opt") then
        vim.uv.fs_rename(site_pack .. "/" .. dir, data_dir .. "/" .. dir .. ".disabled")
      end
    end
  end

  local translated = M.translate_all(specs)

  -- Restore from snapshot if available for version pinning
  local snapshot_name = "nvim-plugins"
  local ok_snap, _ = pcall(vim.pack.restore, snapshot_name, { silent = true })

  vim.api.nvim_create_autocmd("PackChanged", {
    callback = function(ev)
      local d = ev.data
      if not d or not d.spec then return end
      local name = d.spec.name
      if not name then return end
      local data = _spec_data[name] or {}
      if data.build and (d.kind == "update" or d.kind == "install") then
        if not d.active then
          pcall(M.add_to_rtp, name)
        end
        pcall(run_build, name, data.build)
      end
    end,
  })

  local add_startup = {}
  local add_deferred = {}

  for i, spec in ipairs(specs) do
    local trigger = spec.trigger or {}
    local has_triggers = next(trigger)
    if has_triggers and not trigger.startup then
      table.insert(add_deferred, translated[i])
    else
      table.insert(add_startup, translated[i])
    end
  end

  -- Collect dependency URLs not already in the specs list.
  -- vim.pack has no native dependency mechanism, so we add them as
  -- minimal startup entries (no triggers, no config — just installed).
  local spec_urls = {}
  local name_to_url = {}
  for _, spec in ipairs(specs) do
    spec_urls[spec.url] = true
    local name = spec.name or spec.url:match("[^/]+$")
    name_to_url[name] = spec.url
  end
  local dep_entries = {}
  for _, spec in ipairs(specs) do
    local deps = spec.dependencies
    if deps then
      local dep_list = type(deps) == "table" and deps or { deps }
      for _, dep in ipairs(dep_list) do
        local dep_url
        if type(dep) == "string" then
          dep_url = dep:find("/") and dep or name_to_url[dep]
        else
          dep_url = dep.url
        end
        if dep_url and not spec_urls[dep_url] then
          spec_urls[dep_url] = true
          local dep_name = dep_url:match("[^/]+$")
          table.insert(dep_entries, {
            src = "https://github.com/" .. dep_url,
            name = dep_name,
          })
        end
      end
    end
  end

  -- Add all plugins in one call so the lockfile is unified.
  -- Split into new vs existing to minimise work (and avoid double-sourcing).
  local all_new = {}
  local all_existing = {}
  for _, entry in ipairs(add_startup) do
    if vim.uv.fs_stat(core_path(entry.name)) then
      table.insert(all_existing, entry)
    else
      table.insert(all_new, entry)
    end
  end
  for _, entry in ipairs(add_deferred) do
    if vim.uv.fs_stat(core_path(entry.name)) then
      table.insert(all_existing, entry)
    else
      table.insert(all_new, entry)
    end
  end
  for _, entry in ipairs(dep_entries) do
    if vim.uv.fs_stat(core_path(entry.name)) then
      table.insert(all_existing, entry)
    else
      table.insert(all_new, entry)
    end
  end

  local add_opts = vim.tbl_deep_extend("force", { confirm = false }, opts.pack_add_opts or {})
  if #all_new > 0 then
    vim.pack.add(all_new, add_opts)
  end

  -- Sort startup plugins by priority (higher = first)
  local priority_map = {}
  for _, spec in ipairs(specs) do
    local pname = spec.name or spec.url:match("[^/]+$")
    if spec.priority then
      priority_map[pname] = spec.priority
    end
  end
  table.sort(add_startup, function(a, b)
    local pa = priority_map[a.name] or 50
    local pb = priority_map[b.name] or 50
    return pa > pb
  end)

  -- Activate startup plugins (add to rtp; runtime! will source plugin files)
  for _, ts in ipairs(add_startup) do
    pcall(M.add_to_rtp, ts.name)
  end
  for _, entry in ipairs(dep_entries) do
    pcall(M.add_to_rtp, entry.name)
  end

  for _, spec in ipairs(specs) do
    local trigger = spec.trigger or {}
    local has_triggers = next(trigger)
    if has_triggers and not trigger.startup then
      local name = spec.name or spec.url:match("[^/]+$")
      register_conds(name, trigger)
    end
  end

  -- Save snapshot for future restoration
  pcall(vim.pack.snapshot, snapshot_name, { force = true })
end

return M
