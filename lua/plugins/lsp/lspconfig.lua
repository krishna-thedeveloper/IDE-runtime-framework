return {
    url = "neovim/nvim-lspconfig",
    trigger = { require = "lspconfig" },
    dependencies = { "williamboman/mason-lspconfig.nvim" },
    config = function()
        require("managers.lsp").setup()
    end,
}
