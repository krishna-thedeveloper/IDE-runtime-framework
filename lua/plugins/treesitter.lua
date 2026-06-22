return {
    url = "nvim-treesitter/nvim-treesitter",
    trigger = { startup = true },
    build = ":TSUpdate",
    config = function()
        require("nvim-treesitter").setup({
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
        })
    end,
}
