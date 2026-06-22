return {
    {
        "folke/persistence.nvim",
        event = "BufReadPre",
        keys = {
            { "<leader>Ss", function() require("persistence").load() end, desc = "Restore Session" },
            { "<leader>Sl", function() require("persistence").load({ last = true }) end, desc = "Restore Last Session" },
            { "<leader>Sd", function() require("persistence").stop() end, desc = "Don't Save Session" },
        },
        opts = {
            dir = vim.fn.stdpath("state") .. "/sessions/",
            need = 1,
            branch = true,
        },
        config = function(_, opts)
            require("persistence").setup(opts)
        end,
    },
}
