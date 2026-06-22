local M = {}

local state_dir = vim.fn.stdpath("state")
local state_file = state_dir .. "/focus.txt"
local events = require("managers.events")
local active = nil

function M.is_active()
  return active == true
end

function M.enter()
  active = true
  require("statusline").set_layout("minimal")
  vim.opt.showtabline = 0
  pcall(function()
    require("ibl").setup({ enabled = false })
  end)
  vim.cmd("redrawstatus!")
  vim.notify("Focus mode on", vim.log.levels.INFO)
  M.save(true)
  events.emit("focus_changed", { active = true })
end

function M.exit()
  active = false
  vim.cmd("redrawstatus!")
  vim.notify("Focus mode off", vim.log.levels.INFO)
  M.save(false)
  events.emit("focus_changed", { active = false })
end

function M.toggle()
  if active then
    M.exit()
  else
    M.enter()
  end
end

function M.save(state)
  vim.fn.mkdir(state_dir, "p")
  local f = io.open(state_file, "w")
  if f then
    f:write(state and "1" or "0")
    f:close()
  end
end

function M.load_state()
  local f = io.open(state_file, "r")
  if f then
    local val = f:read("*l")
    f:close()
    active = val and vim.trim(val) == "1"
  end
end

function M.setup()
  M.load_state()
  if active then
    require("statusline").set_layout("minimal")
    vim.opt.showtabline = 0
  end
end

vim.keymap.set("n", "<leader>z", M.toggle, { desc = "Toggle focus mode" })

return M
