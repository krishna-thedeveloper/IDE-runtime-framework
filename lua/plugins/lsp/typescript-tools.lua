local engines = require("managers.language_engine")

return {
    url = "pmizio/typescript-tools.nvim",
    dependencies = { "nvim-lua/plenary.nvim", "neovim/nvim-lspconfig" },
    enabled = function() return engines.is_active("typescript", "typescript_tools") end,
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
