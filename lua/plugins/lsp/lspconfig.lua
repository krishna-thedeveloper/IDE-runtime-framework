return {
    url = "neovim/nvim-lspconfig",
    on_require = "lspconfig",
    dependencies = { "williamboman/mason-lspconfig.nvim" },
    config = function()
        require("managers.lsp").setup()
    end,
}
