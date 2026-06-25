local M = {}

function M.setup(opts)
    require("conform").setup(opts)

    vim.keymap.set("n", "<leader>cf", function()
        M.format()
    end, { desc = "Format file" })
end

function M.format(opts)
    opts = opts or {}
    require("conform").format(vim.tbl_deep_extend("force", {
        async = true,
        lsp_fallback = true,
        stop_after_first = true,
    }, opts))
end

return M
