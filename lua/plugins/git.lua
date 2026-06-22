return {
    url = "lewis6991/gitsigns.nvim",
    trigger = { event = { "BufReadPre", "BufNewFile" } },
    config = function()
        require("managers.git").setup()
    end,
}
