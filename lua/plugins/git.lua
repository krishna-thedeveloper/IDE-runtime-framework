return {
    url = "lewis6991/gitsigns.nvim",
    on_event = { "BufReadPre", "BufNewFile" },
    config = function()
        require("managers.git").setup()
    end,
}
