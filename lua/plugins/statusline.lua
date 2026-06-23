return {
    url = "rebelot/heirline.nvim",
    trigger = { lazy = true },
    dependencies = { "nvim-tree/nvim-web-devicons" },
    config = function()
        require("managers.density").setup()
    end,
}
