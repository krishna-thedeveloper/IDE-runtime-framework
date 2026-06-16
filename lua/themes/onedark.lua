return {
    {
        name = "onedark",
        plugin = "onedark.nvim",
        group = "onedark",
        apply = function()
            vim.cmd("highlight clear")
            vim.cmd("syntax reset")
            require("onedark").setup({
                style = "dark",
                transparent = true,
                term_colors = true,
                ending_tildes = false,
                code_style = {
                    comments = "italic",
                    keywords = "none", functions = "none",
                    strings = "none", variables = "none",
                },
                diagnostics = {
                    darker = true, undercurl = true, background = true,
                },
                highlights = {
                    NormalFloat = { bg = "#282c34" },
                    FloatBorder = { bg = "#282c34", fg = "#61afef" },
                    NormalSB = { bg = "#282c34" },
                },
            })
            require("onedark").load()
            vim.cmd("syntax on")
        end,
    },
}
