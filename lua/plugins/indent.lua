return {
    url = "lukas-reineke/indent-blankline.nvim",
    trigger = { lazy = true },
    config = function()
        local ibl = require("ibl")
        local opts = require("managers.indent").setup_config(true)
        ibl.setup(opts)

        require("managers.indent").apply_highlights()

        vim.api.nvim_create_autocmd("ColorScheme", {
            group = vim.api.nvim_create_augroup("indent_ibl", { clear = true }),
            callback = function()
                require("managers.indent").apply_highlights()
            end,
        })
    end,
}
