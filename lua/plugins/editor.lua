return {
    {
        url = "numToStr/Comment.nvim",
        trigger = { require = "Comment" },
        config = function()
            require("Comment").setup({})
        end,
    },
    {
        url = "kylechui/nvim-surround",
        trigger = { require = "nvim-surround" },
        config = function()
            require("nvim-surround").setup({})
        end,
    },
    {
        url = "echasnovski/mini.pairs",
        trigger = { event = "InsertEnter" },
        config = function()
            require("mini.pairs").setup({})
        end,
    },
    {
        url = "stevearc/oil.nvim",
        trigger = { require = "oil" },
        config = function()
            require("oil").setup({})
        end,
    },
}
