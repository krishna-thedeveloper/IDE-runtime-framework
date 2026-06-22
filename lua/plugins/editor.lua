return {
    {
        url = "numToStr/Comment.nvim",
        config = function()
            require("Comment").setup({})
        end,
    },
    {
        url = "kylechui/nvim-surround",
        config = function()
            require("nvim-surround").setup({})
        end,
    },
    {
        url = "echasnovski/mini.pairs",
        config = function()
            require("mini.pairs").setup({})
        end,
    },
    {
        url = "stevearc/oil.nvim",
        config = function()
            require("oil").setup({})
        end,
    },
}
