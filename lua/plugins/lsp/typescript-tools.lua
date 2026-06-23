local config = require("config.typescript")

return {
    url = "pmizio/typescript-tools.nvim",
    dependencies = { "nvim-lua/plenary.nvim", "neovim/nvim-lspconfig" },
    enabled = function() return config.provider == "typescript-tools" end,
    trigger = { ft = { "typescript", "typescriptreact", "javascript", "javascriptreact" } },
    config = function()
        require("typescript-tools").setup({
            settings = {
                separate_diagnostic_server = false,
                tsserver_file_preferences = {
                    importModuleSpecifierPreference = "relative",
                },
            },
        })
    end,
}
