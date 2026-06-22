local M = {}

local indent_color = "#3b4261"
local scope_color = "#5c6370"

local exclude_filetypes = {
  "help", "dashboard", "neo-tree", "Trouble",
  "lazy", "mason", "notify", "noice", "oil",
  "toggleterm", "lspinfo",
}

function M.setup_config(enabled)
  return {
    enabled = enabled,
    indent = {
      char = "│",
      tab_char = "│",
      highlight = { "IblIndent", "IblIndent" },
      smart_indent_cap = true,
    },
    scope = {
      enabled = enabled,
      show_start = true,
      show_end = true,
      highlight = "IblScope",
      injected_languages = false,
      priority = 500,
    },
    exclude = {
      filetypes = vim.list_extend({}, exclude_filetypes),
    },
  }
end

function M.apply_highlights()
  vim.api.nvim_set_hl(0, "IblIndent", { fg = indent_color })
  vim.api.nvim_set_hl(0, "IblScope", { fg = scope_color })
end

function M.get_colors()
  return { indent = indent_color, scope = scope_color }
end

return M
