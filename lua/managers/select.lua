local M = {}

function M.select(items, opts, on_choice)
  local picker = require("managers.picker")
  local active = picker.get_active_name()
  if active == "snacks" then
    pcall(require, "snacks")
  elseif active == "telescope" then
    pcall(require, "telescope")
  end
  vim.ui.select(items, opts, on_choice)
end

return M
