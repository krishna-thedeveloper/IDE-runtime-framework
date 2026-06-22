return {
    {
        "lukas-reineke/indent-blankline.nvim",
        main = "ibl",
        event = "VeryLazy",
        opts = function()
            return require("managers.indent").setup_config(true)
        end,
        config = function(_, opts)
            local ibl = require("ibl")
            ibl.setup(opts)

            require("managers.indent").apply_highlights()

            vim.api.nvim_create_autocmd("ColorScheme", {
                callback = function()
                    require("managers.indent").apply_highlights()
                end,
            })
        end,
    },
}
