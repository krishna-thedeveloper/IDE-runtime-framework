local M = {}

local state_dir = vim.fn.stdpath("state")
local state_file = state_dir .. "/picker.txt"

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
  return M._active or "telescope"
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
  vim.fn.mkdir(state_dir, "p")
  local f = io.open(state_file, "w")
  if f then
    f:write(name)
    f:close()
  end
end

local function restore()
  local f = io.open(state_file, "r")
  if f then
    local name = f:read("*l")
    f:close()
    name = name and vim.trim(name) or ""
    if name ~= "" and M._adapters[name] then
      M._active = name
    end
  end
end

local function discover_adapters()
  local ok, files = pcall(vim.fn.readdir, vim.fn.stdpath("config") .. "/lua/managers/picker/adapters")
  if not ok or not files then
    return
  end
  for _, file in ipairs(files) do
    local mod = file:match("^(.*)%.lua$")
    if mod and mod ~= "init" then
      pcall(function()
        local adapter = require("managers.picker.adapters." .. mod)
        if adapter then
          M.register(mod, adapter)
        end
      end)
    end
  end
end

discover_adapters()
restore()

function M._load_active()
  if M._active == "snacks" then
    pcall(require, "snacks")
  elseif M._active == "telescope" then
    pcall(require, "telescope")
  end
end

function M.select()
    M._load_active()
    vim.ui.select(adapter_order, {
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
