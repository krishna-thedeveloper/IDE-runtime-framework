return {
    {
        "lukas-reineke/indent-blankline.nvim",
        main = "ibl",
        event = "VeryLazy",
        opts = {
            indent = {
                char = "│",
                tab_char = "│",
                highlight = {
                    "IblIndent",
                    "IblIndent",
                },
                smart_indent_cap = true,
            },
            scope = {
                enabled = true,
                show_start = true,
                show_end = true,
                highlight = "IblScope",
                injected_languages = false,
                priority = 500,
            },
            exclude = {
                filetypes = {
                    "help",
                    "dashboard",
                    "neo-tree",
                    "Trouble",
                    "lazy",
                    "mason",
                    "notify",
                    "noice",
                    "oil",
                    "toggleterm",
                    "lspinfo",
                },
            },
        },
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
