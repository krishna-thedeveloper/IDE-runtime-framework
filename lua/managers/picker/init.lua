local M = {}

local state = require("managers.state")
local state_file = vim.fn.stdpath("state") .. "/picker.txt"

M._adapters = {}
M._active = nil

local adapter_order = {}

function M.register(name, adapter)
  M._adapters[name] = adapter
  table.insert(adapter_order, name)
  if not M._active then
    M._active = name
  end
end

function M.use(name)
  if not M._adapters[name] then
    vim.notify("Picker '" .. name .. "' not found", vim.log.levels.WARN)
    return
  end
  local prev = M._active
  M._active = name
  M._save(name)
  if prev and M._adapters[prev] and M._adapters[prev].cleanup then
    M._adapters[prev].cleanup()
  end
  vim.notify("Picker: " .. (M._adapters[name].label or name), vim.log.levels.INFO)
end

function M.cycle()
  if #adapter_order == 0 then
    return
  end
  local idx = 1
  for i, name in ipairs(adapter_order) do
    if name == M._active then
      idx = (i % #adapter_order) + 1
      break
    end
  end
  M.use(adapter_order[idx])
end

function M.get_active_name()
  return M._active
end

local methods = {
  "find_files", "live_grep", "buffers", "oldfiles",
  "help_tags", "git_files", "git_commits", "references",
}

for _, method in ipairs(methods) do
  M[method] = function(...)
    if not M._active or not M._adapters[M._active] then
      vim.notify("No active picker adapter", vim.log.levels.ERROR)
      return
    end
    local fn = M._adapters[M._active][method]
    if not fn then
      vim.notify("Picker '" .. M._active .. "' does not implement '" .. method .. "'", vim.log.levels.WARN)
      return
    end
    return fn(...)
  end
end

function M._save(name)
  state.save(name, state_file)
end

local function restore()
  local saved = state.load(state_file, M._adapters)
  if saved then
    M._active = saved
  end
end

for mod, adapter in pairs(require("managers.discover").adapters("managers.picker.adapters")) do
  M.register(mod, adapter)
end
restore()

function M.select()
    require("managers.select").select(adapter_order, {
        prompt = "Select picker",
        format_item = function(item)
            local label = (M._adapters[item] and M._adapters[item].label) or item:gsub("^.", string.upper)
            if item == M._active then
                return label .. "  ●"
            end
            return label
        end,
    }, function(choice)
        if choice then
            M.use(choice)
        end
    end)
end

vim.keymap.set("n", "<leader>fp", M.cycle, { desc = "Cycle picker" })
vim.keymap.set("n", "<leader>sp", M.select, { desc = "Select picker" })

return M
