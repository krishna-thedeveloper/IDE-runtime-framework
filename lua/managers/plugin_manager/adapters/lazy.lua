local M = {}

M.install_dir = vim.fn.stdpath("data") .. "/lazy"

local generic_fields = {
  url = true,
  trigger = true,
  load = true,
  category = true,
  optional = true,
  metadata = true,
  condition = true,
}

function M.translate(spec)
  if not spec.url then
    return spec
  end

  local result = { spec.url }

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

    if t.startup then
      result.lazy = false
    end

    if t.lazy then
      result.event = "VeryLazy"
    elseif t.event then
      result.event = t.event
    end

    if t.cmd then
      result.cmd = t.cmd
    end

    if t.keymap then
      result.keys = t.keymap
    end

    if t.require then
      result.module = t.require
    end

    if t.ft then
      result.ft = t.ft
    end
  end

  if spec.condition then
    result.cond = spec.condition
  end

  -- lazy.nvim auto-loads plugins with config but no triggers at startup.
  -- Explicitly set lazy=true so config-only plugins stay lazy.
  if result.lazy == nil then
    local has_trigger = result.event or result.cmd or result.keys or result.module or result.ft
    if spec.config and not has_trigger then
      result.lazy = true
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
  local lazy_specs = {}
  for _, spec in ipairs(specs) do
    table.insert(lazy_specs, M.translate(spec))
  end
  return lazy_specs
end

function M.load_plugin(name)
  pcall(require("lazy").load, { plugins = name })
end

local function module_prefix(name)
  return name:match("^([^.]+)")
end

function M.cleanup(name)
  local prefix = module_prefix(name)
  if prefix then
    for k in pairs(package.loaded) do
      if type(k) == "string" and k:find("^" .. prefix:gsub("[^%w_]", "%%%1")) then
        package.loaded[k] = nil
      end
    end
  end
  local config = require("lazy.core.config")
  for _, plugin in pairs(config.plugins) do
    if plugin.name == name then
      if plugin._ then
        plugin._.loaded = nil
      end
    end
  end
end

function M.plugin_path(url)
  local dir_name = url:match("[^/]+$")
  return M.install_dir .. "/" .. dir_name
end

function M.bootstrap(specs, opts)
  opts = opts or {}
  local lazy_opts = opts.lazy_opts or {}

  local lazypath = M.install_dir .. "/lazy.nvim"
  if not (vim.uv or vim.loop).fs_stat(lazypath) then
    local lazyrepo = "https://github.com/folke/lazy.nvim.git"
    local out = vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath })
    if vim.v.shell_error ~= 0 then
      vim.api.nvim_echo({
        { "Failed to clone lazy.nvim:\n", "ErrorMsg" },
        { out, "WarningMsg" },
        { "\nPress any key to exit..." },
      }, true, {})
      vim.fn.getchar()
      os.exit(1)
    end
  end

  vim.opt.rtp:prepend(lazypath)

  local lazy_specs = M.translate_all(specs)
  require("lazy").setup(lazy_specs, lazy_opts)
end

return M
