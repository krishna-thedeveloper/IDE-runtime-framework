local M = {}

local state = require("managers.state")
local state_file = vim.fn.stdpath("state") .. "/focus.txt"
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

function M.save(s)
  state.save(s and "1" or "0", state_file)
end

function M.load_state()
  active = state.load(state_file) == "1"
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
