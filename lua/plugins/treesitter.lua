return {
    {
        "nvim-treesitter/nvim-treesitter",
        lazy = false,
        build = ":TSUpdate",

        opts = {
            ensure_installed = {
                "lua",
                "javascript",
                "typescript",
                "tsx",
                "proto",
                "json",
                "yaml",
                "toml",
                "bash",
                "markdown",
                "markdown_inline",
            },

            highlight = {
                enable = true,
            },

            indent = {
                enable = true,
            },
        },

        config = function(_, opts)
            local TS = require("nvim-treesitter")
            TS.setup(opts)
        end,
    },
}
