local M = {}

local generic_fields = {
  url = true, trigger = true, load = true,
  category = true, optional = true, metadata = true,
  condition = true, enabled = true, priority = true,
}

local _spec_data = {}
local _loading = {}
local _loaded = {}

local function _log(fmt, ...)
  vim.api.nvim_echo({{ "[rocks.nvim] " .. string.format(fmt, ...):sub(1, 200), "WarningMsg" }}, false, {})
end

local function _load(fn)
  local ok, err = pcall(fn)
  if not ok then
    _log("Error: %s", tostring(err))
  end
end

-- ── Lazy loading conds ────────────────────────────────────────────
local function event_cond(events, name)
  return function()
    local group = vim.api.nvim_create_augroup("RocksEvent", { clear = false })
    vim.api.nvim_create_autocmd(type(events) == "table" and events or { events }, {
      group = group, once = true,
      callback = function() _load(function() M.load_plugin(name) end) end,
    })
  end
end

local function ft_cond(fts, name)
  return function()
    local group = vim.api.nvim_create_augroup("RocksFt", { clear = false })
    vim.api.nvim_create_autocmd("FileType", {
      group = group, once = true, pattern = fts,
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
          _log("Error: %s", tostring(err))
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
        local lhs, rhs = km[1], km[2]
        local mode = km.mode or "n"
        local opts = { desc = km.desc or "Rocks" }
        vim.keymap.set(mode, lhs, function()
          _load(function() M.load_plugin(name) end)
          if type(rhs) == "function" then rhs()
          elseif rhs then vim.cmd(rhs)
          else vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes(lhs, true, false, true), "m", true) end
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
          end, { nargs = "*", desc = "Rocks lazy: " .. c })
        end
      end
    end
  end
end

local function register_conds(name, trigger)
  local conds = {}
  if trigger.lazy then table.insert(conds, lazy_cond(name)) end
  if trigger.event then table.insert(conds, event_cond(trigger.event, name)) end
  if trigger.cmd then table.insert(conds, cmd_cond(trigger.cmd, name)) end
  if trigger.keymap then table.insert(conds, keymap_cond(trigger.keymap, name)) end
  if trigger.require then table.insert(conds, require_cond(trigger.require, name)) end
  if trigger.ft then table.insert(conds, ft_cond(trigger.ft, name)) end
  local has_auto = trigger.lazy or trigger.event or trigger.ft
  if not has_auto and #conds > 0 then table.insert(conds, 1, lazy_cond(name)) end
  for _, cond in ipairs(conds) do cond() end
end

-- ── Config / Build helpers ────────────────────────────────────────
local function run_config(name, spec_data)
  if spec_data.init then
    local ok, err = pcall(spec_data.init)
    if not ok then _log("init error for %s: %s", name, tostring(err)) end
  end
  if spec_data.config then
    local ok, err = pcall(spec_data.config)
    if not ok then _log("config error for %s: %s", name, tostring(err)) end
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
    if not ok then _log("build error for %s: %s", name, tostring(err)) end
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

-- ── Core adapter API ─────────────────────────────────────────────
local function rocks_path()
  return vim.fn.stdpath("data") .. "/rocks"
end

local function site_opt_dir()
  return rocks_path() .. "/site/pack/luarocks/opt"
end

function M.plugin_path(url)
  local dir_name = url and url:match("[^/]+$")
  if not dir_name then return nil end
  return site_opt_dir() .. "/" .. dir_name
end

function M.load_plugin(name)
  if _loaded[name] or _loading[name] then return end
  _loading[name] = true

  local ok, err = pcall(function()
    local data = _spec_data[name]
    if data then
      -- Packadd dependencies first
      if data.dependencies then
        local dep_list = type(data.dependencies) == "table" and data.dependencies or { data.dependencies }
        for _, dep in ipairs(dep_list) do
          local dep_url = type(dep) == "string" and (dep:find("/") and dep or nil) or dep.url
          local dep_name = dep_url and dep_url:match("[^/]+$") or (type(dep) == "string" and dep or nil)
          if dep_name and dep_name ~= name then
            local dep_data = _spec_data[dep_name]
            if dep_data and not _loaded[dep_name] then
              M.load_plugin(dep_name)
            end
          end
        end
      end

      -- Prepend to rtp and run build before packadd (some plugins
      -- call require in their plugin/ file — blink.cmp, etc.)
      local path = M.plugin_path(data.url)
      if path then
        vim.opt.rtp:prepend(path)
      end

      if data.build and not data._build_done then
        run_build(name, data.build)
        data._build_done = true
      end

      vim.cmd("packadd " .. name)

      run_config(name, data)
    end
  end)

  _loading[name] = nil
  if ok then _loaded[name] = true end

  if not ok then
    _log("load_plugin(%s): %s", name, tostring(err))
  end
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
  if not spec.url then return spec end
  local name = spec.name or spec.url:match("[^/]+$")
  _spec_data[name] = {
    config = spec.config, init = spec.init, opts = spec.opts,
    build = spec.build, url = spec.url,
    dependencies = spec.dependencies,
  }
  return { name = name, source = "https://github.com/" .. spec.url }
end

function M.translate_all(specs)
  local result = {}
  for _, spec in ipairs(specs) do
    table.insert(result, M.translate(spec))
  end
  return result
end

-- ── Bootstrap ─────────────────────────────────────────────────────
function M.bootstrap(specs, opts)
  opts = opts or {}
  local rp = rocks_path()
  local site_opt = site_opt_dir()

  -- Disable conflicting pack directories from other adapters
  local data_dir = vim.fn.stdpath("data")
  local site_pack = data_dir .. "/site/pack"
  local ok, entries = pcall(vim.fn.readdir, site_pack)
  if ok then
    for _, dir in ipairs(entries) do
      if dir ~= "luarocks" then
        local opt = site_pack .. "/" .. dir .. "/opt"
        if vim.uv.fs_stat(opt) then
          vim.uv.fs_rename(site_pack .. "/" .. dir, data_dir .. "/" .. dir .. ".disabled")
        end
      end
    end
  end

  -- Ensure site/pack/luarocks/opt directory exists
  vim.fn.mkdir(site_opt, "p")

  -- Bootstrap luarocks + rocks.nvim via git if not present
  local rocks_nvim_git = rp .. "/rocks.nvim"
  if not vim.uv.fs_stat(rocks_nvim_git) then
    vim.api.nvim_echo({{ "[rocks.nvim] Cloning rocks.nvim...", "Info" }}, false, {})
    local out = vim.fn.system({
      "git", "clone", "--depth=1", "--filter=blob:none",
      "https://github.com/lumen-oss/rocks.nvim", rocks_nvim_git,
    })
    if vim.v.shell_error ~= 0 then
      _log("clone failed: %s", out)
      return
    end
  end

  -- Try installing luarocks and rocks.nvim via luarocks if lua is available
  local has_lua = vim.fn.executable("lua") == 1
    or vim.fn.executable("lua5.1") == 1
    or vim.fn.executable("luajit") == 1

  local rocks_nvim_via_luarocks = rp .. "/lib/luarocks/rocks-5.1/rocks.nvim"
  local luarocks_from_luarocks = not vim.tbl_isempty(
    vim.fn.glob(rp .. "/lib/luarocks/rocks-5.1/luarocks/*/bin/luarocks", false, true))

  if has_lua and not vim.uv.fs_stat(rocks_nvim_via_luarocks) then
    vim.api.nvim_echo({{ "[rocks.nvim] Installing rocks.nvim via luarocks...", "Info" }}, false, {})

    -- Ensure luarocks binary is available
    local lr_bin = vim.fn.executable("luarocks") == 1 and "luarocks"
      or (vim.fn.executable(rp .. "/bin/luarocks") == 1 and rp .. "/bin/luarocks")
      or nil

    if not lr_bin then
      -- Build luarocks from source
      local tmp = vim.fs.joinpath(vim.fn.stdpath("run"),
        ("luarocks-%X"):format(math.random(256 ^ 7)))
      local code = vim.fn.system({
        "git", "clone", "--filter=blob:none",
        "https://github.com/luarocks/luarocks.git", tmp,
      })
      if vim.v.shell_error == 0 then
        vim.fn.system("cd " .. vim.fn.shellescape(tmp)
          .. " && sh configure --prefix=" .. vim.fn.shellescape(rp)
          .. " --lua-version=5.1 --force-config")
        if vim.v.shell_error == 0 then
          vim.fn.system("cd " .. vim.fn.shellescape(tmp) .. " && make install")
        end
        vim.fn.delete(tmp, "rf")
      end
      lr_bin = vim.fn.executable(rp .. "/bin/luarocks") == 1 and rp .. "/bin/luarocks" or nil
    end

    if lr_bin then
      local servers = "https://luarocks.org/manifests/neorocks/"
      local uname = vim.uv.os_uname()
      local arch_map = {
        Linux = { x86_64 = "linux-x86_64" },
        Darwin = { arm64 = "macosx-aarch64", x86_64 = "macosx-x86_64" },
        Windows_NT = { x86_64 = "win32-x86_64" },
      }
      local os_map = arch_map[uname.sysname]
      local arch_opt = os_map and os_map[uname.machine]
      if arch_opt then
        servers = "https://lux.lumen-labs.org/rocks-binaries/"
      end
      vim.fn.system({ lr_bin, "--lua-version=5.1", "--tree=" .. rp,
        "--server=" .. servers, "install", "rocks.nvim" })
      if vim.v.shell_error == 0 then
        vim.api.nvim_echo({{ "[rocks.nvim] rocks.nvim installed via luarocks.", "Info" }}, false, {})
      end
    end
  end

  -- Add rocks.nvim to rtp — prefer luarocks install, fall back to git clone
  local rocks_nvim_rtp
  if vim.uv.fs_stat(rocks_nvim_via_luarocks) then
    rocks_nvim_rtp = rocks_nvim_via_luarocks .. "/*"
    -- Set up package.path for luarocks-installed rocks
    package.path = package.path .. ";" .. rp .. "/share/lua/5.1/?.lua"
      .. ";" .. rp .. "/share/lua/5.1/?/init.lua"
    package.cpath = package.cpath .. ";" .. rp .. "/lib/lua/5.1/?.so"
  else
    rocks_nvim_rtp = rocks_nvim_git .. "/*"
  end
  vim.opt.runtimepath:append(rocks_nvim_rtp)

  -- Set up rocks.nvim config
  vim.g.rocks_nvim = { rocks_path = rp }
  vim.fn.mkdir(rp .. "/share/lua/5.1", "p")
  vim.fn.mkdir(rp .. "/lib/lua/5.1", "p")

  -- Pre-install ALL plugins via git clone into site/pack/luarocks/opt
  local translated = M.translate_all(specs)

  -- Build URL→name lookup for dependency resolution
  local spec_urls = {}
  local name_to_url = {}
  for _, spec in ipairs(specs) do
    spec_urls[spec.url] = true
    local name = spec.name or spec.url:match("[^/]+$")
    name_to_url[name] = spec.url
  end

  -- Collect unresolved dependency URLs
  local dep_urls = {}
  for _, spec in ipairs(specs) do
    local deps = spec.dependencies
    if deps then
      local dep_list = type(deps) == "table" and deps or { deps }
      for _, dep in ipairs(dep_list) do
        local dep_url = type(dep) == "string"
          and (dep:find("/") and dep or name_to_url[dep])
          or dep.url
        if dep_url and not spec_urls[dep_url] then
          spec_urls[dep_url] = true
          dep_urls[dep_url] = true
        end
      end
    end
  end

  local function ensure_cloned(name, url)
    local install_path = site_opt .. "/" .. name
    if not vim.uv.fs_stat(install_path) then
      local out = vim.fn.system({
        "git", "clone", "--depth=1", "--filter=blob:none",
        "https://github.com/" .. url, install_path,
      })
      if vim.v.shell_error ~= 0 then
        _log("clone failed for %s: %s", url, out)
      end
    end
  end

  for _, spec in ipairs(specs) do
    local name = spec.name or spec.url:match("[^/]+$")
    ensure_cloned(name, spec.url)
  end

  -- Clone unresolved dependencies
  for dep_url, _ in pairs(dep_urls) do
    local dep_name = dep_url:match("[^/]+$")
    _spec_data[dep_name] = { url = dep_url }
    ensure_cloned(dep_name, dep_url)
  end

  -- Categorize and load
  local add_startup = {}
  local add_deferred = {}

  for i, spec in ipairs(specs) do
    local trigger = spec.trigger or {}
    local has_triggers = next(trigger)
    if has_triggers and not trigger.startup then
      table.insert(add_deferred, { spec = spec })
    else
      table.insert(add_startup, { spec = spec })
    end
  end

  for _, entry in ipairs(add_startup) do
    local name = entry.spec.name or entry.spec.url:match("[^/]+$")
    _load(function() M.load_plugin(name) end)
  end

  for _, entry in ipairs(add_deferred) do
    local spec = entry.spec
    local trigger = spec.trigger or {}
    local name = spec.name or spec.url:match("[^/]+$")
    register_conds(name, trigger)
  end
end

return M
