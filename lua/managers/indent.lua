local M = {}

local default_indent = "#3b4261"
local default_scope = "#5c6370"

local exclude_filetypes = {
  "help", "dashboard", "neo-tree", "Trouble",
  "lazy", "mason", "notify", "noice", "oil",
  "toggleterm", "lspinfo",
}

local function palette_color(name, fallback)
  local ok, mgr = pcall(require, "managers.theme")
  if ok and mgr and mgr.palette then
    return mgr.palette[name] or fallback
  end
  return fallback
end

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
  local fg = vim.api.nvim_get_hl(0, { name = "LineNr" }).fg
  vim.api.nvim_set_hl(0, "IblIndent", { fg = fg or default_indent })
end

function M.get_colors()
  local fg = vim.api.nvim_get_hl(0, { name = "LineNr" }).fg
  return { indent = fg and string.format("#%06x", fg) or default_indent,
           scope = palette_color("gray", default_scope) }
end

return M
