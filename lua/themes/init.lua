local M = {}

M.palette = {
    red = "#e06c75", green = "#98c379", yellow = "#e5c07b",
    blue = "#61afef", purple = "#c678dd", cyan = "#56b6c2",
    white = "#abb2bf", gray = "#5c6370", dark_bg = "#282c34",
}

function M.update_palette() end

function M.get_active_theme()
    return "catppuccin"
end

function M.get_active_group()
    return "catppuccin"
end

function M.is_light_variant(_name)
    return false
end

function M.save_theme(_name) end

function M.load_theme(name)
    vim.cmd.colorscheme(name)
end

function M.show_current_theme()
    vim.notify('Current theme: ' .. M.get_active_theme(), vim.log.levels.INFO)
end

function M.cycle()
    M.load_theme(M.get_active_theme())
end

vim.keymap.set("n", "<leader>tc", M.cycle, { desc = "Cycle theme" })
vim.keymap.set("n", "<leader>ts", M.show_current_theme, { desc = "Show current theme" })

vim.api.nvim_create_autocmd("ColorScheme", {
    group = vim.api.nvim_create_augroup("themes_palette", { clear = true }),
    callback = M.update_palette,
})

return M
