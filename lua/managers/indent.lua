local M = {}

local indent_color = "#3b4261"
local scope_color = "#5c6370"

function M.apply_highlights()
  vim.api.nvim_set_hl(0, "IblIndent", { fg = indent_color })
  vim.api.nvim_set_hl(0, "IblScope", { fg = scope_color })
end

function M.get_colors()
  return { indent = indent_color, scope = scope_color }
end

return M
