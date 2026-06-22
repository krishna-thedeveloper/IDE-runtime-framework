local M = {}

local state = require("managers.state")
local state_file = vim.fn.stdpath("state") .. "/completion.txt"

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

function M.get_active_name()
  return M._active
end

function M.use(name)
  if not M._adapters[name] then
    vim.notify("Completion '" .. name .. "' not found", vim.log.levels.WARN)
    return
  end
  M._active = name
  M._save(name)
  pcall(vim.lsp.config, "*", { capabilities = M.get_capabilities() })
  vim.notify("Completion: " .. (M._adapters[name].label or name)
    .. " — restart session for full engine swap", vim.log.levels.INFO)
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

function M.get_capabilities()
  if not M._active or not M._adapters[M._active] then
    return vim.lsp.protocol.make_client_capabilities()
  end
  local adapter = M._adapters[M._active]
  if not adapter.get_capabilities then
    return vim.lsp.protocol.make_client_capabilities()
  end
  return adapter.get_capabilities()
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

local function load_adapters()
  local ok, adapter = pcall(require, "managers.completion.adapters.blink_cmp")
  if ok and adapter then
    M.register("blink_cmp", adapter)
  end
end

load_adapters()
restore()

function M.select()
    require("managers.select").select(adapter_order, {
        prompt = "Select completion engine",
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

vim.keymap.set("n", "<leader>cp", M.cycle, { desc = "Cycle completion" })
vim.keymap.set("n", "<leader>sc", M.select, { desc = "Select completion engine" })

return M
