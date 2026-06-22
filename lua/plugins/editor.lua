return {
    {
        url = "numToStr/Comment.nvim",
        on_require = "Comment",
        config = function()
            require("Comment").setup({})
        end,
    },
    {
        url = "kylechui/nvim-surround",
        on_require = "nvim-surround",
        config = function()
            require("nvim-surround").setup({})
        end,
    },
    {
        url = "echasnovski/mini.pairs",
        on_event = "InsertEnter",
        config = function()
            require("mini.pairs").setup({})
        end,
    },
    {
        url = "stevearc/oil.nvim",
        on_require = "oil",
        config = function()
            require("oil").setup({})
        end,
    },
}
