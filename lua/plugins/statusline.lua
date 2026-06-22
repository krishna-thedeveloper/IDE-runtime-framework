return {
    url = "rebelot/heirline.nvim",
    on_lazy = true,
    dependencies = { "nvim-tree/nvim-web-devicons" },
    config = function()
        require("managers.density").setup()
    end,
}
