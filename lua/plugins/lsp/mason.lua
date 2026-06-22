return {
    {
        url = "williamboman/mason.nvim",
        trigger = { require = "mason" },
        config = function()
            require("mason").setup({
                ui = { border = "rounded" },
            })
        end,
    },
    {
        url = "williamboman/mason-lspconfig.nvim",
        trigger = { require = "mason-lspconfig" },
        dependencies = { "mason.nvim" },
        config = function()
            require("mason-lspconfig").setup({
                ensure_installed = {
                    "ts_ls",
                    "lua_ls",
                    "jsonls",
                    "yamlls",
                },
                automatic_installation = false,
            })
        end,
    },
}
