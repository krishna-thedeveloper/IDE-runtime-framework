return {
    {
        "mfussenegger/nvim-lint",
        event = { "BufReadPre", "BufNewFile" },
        opts = {
            events = { "BufWritePost", "BufReadPost", "InsertLeave" },
            linters_by_ft = {
                lua = { "selene" },
            },
        },
        config = function(_, opts)
            require("managers.lint").setup(opts)
        end,
    },
}
