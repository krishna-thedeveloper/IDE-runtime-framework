local M = {}

function M._get_base_dir()
  local info = debug.getinfo(1, "S")
  local src = info and info.source or ""
  local base = src:match("^@(.+)/lua/managers/plugin_manager/init%.lua$")
  return base or vim.fn.stdpath("config")
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

function M.setup(adapter_name, opts)
  opts = opts or {}
  local ok, adapter = pcall(require, "managers.plugin_manager.adapters." .. adapter_name)
  if not ok then
    vim.notify("Unknown plugin manager: " .. adapter_name, vim.log.levels.ERROR)
    return
  end

  M._adapter = adapter
  local specs = M.load_specs()
  adapter.bootstrap(specs, opts)
end

function M.load_plugin(name)
  if not M._adapter or not M._adapter.load_plugin then
    vim.notify("Plugin manager adapter does not support load_plugin", vim.log.levels.ERROR)
    return
  end
  M._adapter.load_plugin(name)
end

return M
