return {
    url = "stevearc/conform.nvim",
    trigger = { event = { "BufReadPre", "BufNewFile" } },
    config = function()
        require("managers.format").setup({
            notify_on_error = false,
            default_format_opts = {
                stop_after_first = true,
            },
            formatters_by_ft = {
                lua = { "stylua" },
                javascript = { "prettierd", "prettier" },
                typescript = { "prettierd", "prettier" },
                javascriptreact = { "prettierd", "prettier" },
                typescriptreact = { "prettierd", "prettier" },
                json = { "prettierd", "prettier" },
                yaml = { "prettierd", "prettier" },
                markdown = { "prettierd", "prettier" },
                ["*"] = { "trim_whitespace" },
            },
            format_on_save = {
                lsp_fallback = true,
                timeout_ms = 500,
                stop_after_first = true,
            },
        })
    end,
}
