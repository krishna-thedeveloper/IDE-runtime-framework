local state = require("managers.state")
local discover = require("managers.discover")

local M = {}

function M.create_adapter_manager(opts)
  local manager = { _adapters = {}, _active = nil, _adapter_order = {} }

  local state_file = opts.state_file

  function manager.register(name, adapter)
    manager._adapters[name] = adapter
    table.insert(manager._adapter_order, name)
    if not manager._active then
      manager._active = name
    end
  end

  function manager.use(name)
    if not manager._adapters[name] then
      vim.notify(opts.desc .. " '" .. name .. "' not found", vim.log.levels.WARN)
      return
    end
    local prev = manager._active
    manager._active = name
    manager._save(name)
    if prev and manager._adapters[prev] and manager._adapters[prev].cleanup then
      manager._adapters[prev].cleanup()
    end
    if opts.on_switch then
      opts.on_switch(prev, name)
    end
    vim.notify(opts.desc .. ": " .. (manager._adapters[name].label or name), vim.log.levels.INFO)
  end

  function manager.cycle()
    if #manager._adapter_order == 0 then
      return
    end
    local idx = 1
    for i, name in ipairs(manager._adapter_order) do
      if name == manager._active then
        idx = (i % #manager._adapter_order) + 1
        break
      end
    end
    manager.use(manager._adapter_order[idx])
  end

  function manager.get_active_name()
    return manager._active
  end

  function manager.get_active_adapter()
    if not manager._active or not manager._adapters[manager._active] then
      return nil
    end
    return manager._adapters[manager._active]
  end

  if opts.methods then
    for _, method in ipairs(opts.methods) do
      manager[method] = function(...)
        if not manager._active or not manager._adapters[manager._active] then
          vim.notify("No active " .. opts.desc .. " adapter", vim.log.levels.ERROR)
          return
        end
        local fn = manager._adapters[manager._active][method]
        if not fn then
          vim.notify(
            opts.desc .. " '" .. manager._active .. "' does not implement '" .. method .. "'",
            vim.log.levels.WARN
          )
          return
        end
        return fn(...)
      end
    end
  end

  function manager._save(name)
    state.save(name, state_file)
  end

  for mod, adapter in pairs(discover.adapters(opts.adapter_prefix)) do
    manager.register(mod, adapter)
  end

  local saved = state.load(state_file, manager._adapters)
  if saved then
    manager._active = saved
  end

  function manager.select()
    local items = vim.tbl_filter(function(name)
      return manager._adapters[name] ~= nil
    end, manager._adapter_order)
    vim.ui.select(items, {
      prompt = "Select " .. opts.desc,
      format_item = function(item)
        local label = (manager._adapters[item] and manager._adapters[item].label)
          or item:gsub("^.", string.upper)
        if item == manager._active then
          return label .. "  ●"
        end
        return label
      end,
    }, function(choice)
      if choice then
        manager.use(choice)
      end
    end)
  end

  if opts.key then
    local cycle_key = opts.cycle_key or ("<leader>" .. opts.key .. "p")
    local select_key = opts.select_key or ("<leader>s" .. opts.key)
    vim.keymap.set("n", cycle_key, manager.cycle, { desc = "Cycle " .. opts.desc })
    vim.keymap.set("n", select_key, manager.select, { desc = "Select " .. opts.desc })
  end

  if opts.setup_fn then
    opts.setup_fn(manager)
  end

  return manager
end

return M
