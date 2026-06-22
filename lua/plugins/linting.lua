return {
    url = "mfussenegger/nvim-lint",
    trigger = { event = { "BufReadPre", "BufNewFile" } },
    config = function()
        require("managers.lint").setup({
            events = { "BufWritePost", "BufReadPost", "InsertLeave" },
            linters_by_ft = {
                lua = { "selene" },
            },
        })
    end,
}
