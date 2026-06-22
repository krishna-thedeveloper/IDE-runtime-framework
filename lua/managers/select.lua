local M = {}

function M.select(items, opts, on_choice)
  vim.ui.select(items, opts, on_choice)
end

return M
