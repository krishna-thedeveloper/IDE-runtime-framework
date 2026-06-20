return {
    {
        "rebelot/heirline.nvim",
        event = "VeryLazy",
        dependencies = { "nvim-tree/nvim-web-devicons" },
        config = function()
            require("statusline").set_layout("full")
        end,
    },
}
