return {
    url = "neovim/nvim-lspconfig",
    trigger = { event = { "BufReadPre", "BufNewFile" } },
    dependencies = { "williamboman/mason-lspconfig.nvim" },
    config = function()
        require("managers.lsp").setup()
    end,
}
