local state = require("managers.state")

local M = {}

-- known spec fields for validation + typo detection
local known_fields = {
  url = true, trigger = true, dependencies = true, build = true,
  version = true, branch = true, tag = true, commit = true,
  config = true, init = true, enabled = true, condition = true,
  priority = true, opts = true, name = true,
  category = true, optional = true, metadata = true,
}

local enabled_file = vim.fn.stdpath("state") .. "/plugins_enabled.txt"

function M._get_base_dir()
  local info = debug.getinfo(1, "S")
  local src = info and info.source or ""
  local base = src:match("^@(.+)/lua/managers/plugin_manager/init%.lua$")
  return base or vim.fn.stdpath("config")
end

function M.validate(spec)
  local errors = {}

  if not spec.url then
    table.insert(errors, "missing 'url' field")
  end

  local old_trigger = { on_startup = "startup", on_lazy = "lazy", on_event = "event",
    on_cmd = "cmd", on_keymap = "keymap", on_require = "require", on_ft = "ft" }
  for old, new in pairs(old_trigger) do
    if spec[old] ~= nil then
      table.insert(errors, "'" .. old .. "' should be inside trigger = { " .. new .. " = ... }")
    end
  end

  for k, _ in pairs(spec) do
    if type(k) == "string" and not known_fields[k] then
      local suggestions = {}
      for f, _ in pairs(known_fields) do
        if k:lower() == f:lower() then
          table.insert(suggestions, f)
        end
      end
      if #suggestions > 0 then
        table.insert(errors, "unknown field '" .. k .. "' (did you mean " .. table.concat(suggestions, ", ") .. "?)")
      elseif not k:match("^_") then
        table.insert(errors, "unknown field '" .. k .. "'")
      end
    end
  end

  if spec.trigger then
    if spec.trigger.startup and spec.trigger.lazy then
      table.insert(errors, "trigger.startup and trigger.lazy are mutually exclusive")
    end
    local old_trigger_inner = { on_event = "event", on_cmd = "cmd", on_keymap = "keymap", on_require = "require" }
    for old, new in pairs(old_trigger_inner) do
      if spec.trigger[old] ~= nil then
        table.insert(errors, "trigger." .. old .. " should be trigger." .. new)
      end
    end
  end

  return errors
end

function M._collect(specs, result, depth)
  if type(result) ~= "table" then
    return
  end
  depth = depth or 0
  if depth > 10 then
    return
  end
  if result.url then
    local errs = M.validate(result)
    if #errs > 0 then
      vim.notify("[plugins] validation failed for " .. (result.url or "?"), vim.log.levels.WARN)
      for _, e in ipairs(errs) do
        vim.notify("  " .. e, vim.log.levels.WARN)
      end
    end
    table.insert(specs, result)
    return
  end
  local count = #result
  if count > 0 then
    for _, item in ipairs(result) do
      M._collect(specs, item, depth + 1)
    end
  else
    table.insert(specs, result)
  end
end

function M.load_specs()
  local base = M._get_base_dir()
  local dir = base .. "/lua/plugins"
  local specs = {}

  local ok, entries = pcall(vim.fn.readdir, dir)
  if not ok then
    return specs
  end

  for _, entry in ipairs(entries) do
    local path = dir .. "/" .. entry
    local stat = vim.uv.fs_stat(path)
    if stat then
      if stat.type == "file" then
        local mod = entry:match("^(.*)%.lua$")
        if mod and mod ~= "init" then
          local ok_spec, result = pcall(require, "plugins." .. mod)
          if ok_spec then
            M._collect(specs, result)
          end
        end
      elseif stat.type == "directory" then
        if vim.uv.fs_stat(path .. "/init.lua") then
          local ok_spec, result = pcall(require, "plugins." .. entry)
          if ok_spec then
            M._collect(specs, result)
          end
        end
      end
    end
  end

  return specs
end

function M._build_registry(specs)
  M._registry = {}
  for _, spec in ipairs(specs) do
    local name = spec.name or spec.url:match("[^/]+$")
    M._registry[name] = spec
    M._registry[spec.url] = spec
  end
end

function M._load_enabled_state()
  M._disabled = {}
  local ok, lines = pcall(vim.fn.readfile, enabled_file)
  if ok and type(lines) == "table" then
    for _, line in ipairs(lines) do
      local name = line:match("^-(.+)$")
      if name then
        M._disabled[name] = true
      end
    end
  end
end

function M._save_enabled_state()
  local lines = {}
  for name, _ in pairs(M._disabled or {}) do
    table.insert(lines, "-" .. name)
  end
  pcall(vim.fn.writefile, lines, enabled_file)
end

function M.get(name)
  if not M._registry then
    return nil
  end
  return M._registry[name]
end

function M.disable(name)
  local spec = M._registry and M._registry[name]
  if not spec then
    vim.notify("Plugin '" .. name .. "' not found in registry", vim.log.levels.WARN)
    return
  end
  M._disabled = M._disabled or {}
  M._disabled[name] = true
  M._save_enabled_state()
  spec.enabled = false
end

function M.enable(name)
  local spec = M._registry and M._registry[name]
  if not spec then
    vim.notify("Plugin '" .. name .. "' not found in registry", vim.log.levels.WARN)
    return
  end
  M._disabled = M._disabled or {}
  M._disabled[name] = nil
  M._save_enabled_state()
  spec.enabled = true
end

function M.disable_category(category)
  if not M._registry then
    return
  end
  for name, spec in pairs(M._registry) do
    if spec.category == category then
      M.disable(name)
    end
  end
end

function M._filter_specs(specs)
  local filtered = {}
  for _, spec in ipairs(specs) do
    if spec.enabled == false then
      goto continue
    end
    if spec.optional then
      local dir_name = spec.url:match("[^/]+$")
      local install_path = vim.fn.stdpath("data") .. "/lazy/" .. dir_name
      if not vim.uv.fs_stat(install_path) then
        goto continue
      end
    end
    table.insert(filtered, spec)
    ::continue::
  end
  return filtered
end

function M.setup(adapter_name, opts)
  opts = opts or {}
  local ok, adapter = pcall(require, "managers.plugin_manager.adapters." .. adapter_name)
  if not ok then
    vim.notify("Unknown plugin manager: " .. adapter_name, vim.log.levels.ERROR)
    return
  end

  M._adapter = adapter
  local specs = M.load_specs()
  M._build_registry(specs)
  M._load_enabled_state()

  for _, spec in ipairs(specs) do
    local name = spec.name or spec.url:match("[^/]+$")
    if M._disabled[name] then
      spec.enabled = false
    end
  end

  local active_specs = M._filter_specs(specs)
  adapter.bootstrap(active_specs, opts)
end

function M.load_plugin(name)
  if not M._adapter or not M._adapter.load_plugin then
    vim.notify("Plugin manager adapter does not support load_plugin", vim.log.levels.ERROR)
    return
  end
  M._adapter.load_plugin(name)
end

return M
