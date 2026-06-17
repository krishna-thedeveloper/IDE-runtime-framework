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

            vim.api.nvim_set_hl(0, "IblIndent", { fg = "#3b4261" })
            vim.api.nvim_set_hl(0, "IblScope", { fg = "#5c6370" })

            vim.api.nvim_create_autocmd("ColorScheme", {
                callback = function()
                    vim.api.nvim_set_hl(0, "IblIndent", { fg = "#3b4261" })
                    vim.api.nvim_set_hl(0, "IblScope", { fg = "#5c6370" })
                end,
            })
        end,
    },
}
