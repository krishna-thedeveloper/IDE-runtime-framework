return {
    url = "lewis6991/gitsigns.nvim",
    config = function()
        require("managers.git").setup()
    end,
}
