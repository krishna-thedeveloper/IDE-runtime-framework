local typescript = require("config.typescript")

return {
    {
        url = "williamboman/mason.nvim",
        trigger = { event = { "BufReadPre", "BufNewFile" } },
        config = function()
            require("mason").setup({
                ui = { border = "rounded" },
            })
        end,
    },
    {
        url = "williamboman/mason-lspconfig.nvim",
        trigger = { event = { "BufReadPre", "BufNewFile" } },
        dependencies = { "mason.nvim" },
        config = function()
            local opts = {
                ensure_installed = {
                    "lua_ls",
                    "jsonls",
                    "yamlls",
                },
                automatic_installation = false,
            }
            if typescript.provider == "ts_ls" then
                table.insert(opts.ensure_installed, "ts_ls")
            else
                opts.automatic_enable = { exclude = { "ts_ls" } }
            end
            require("mason-lspconfig").setup(opts)
        end,
    },
}
