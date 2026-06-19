return {
    {
        "folke/persistence.nvim",
        event = "BufReadPre",
        dependencies = { "folke/which-key.nvim" },
        opts = {
            dir = vim.fn.stdpath("state") .. "/sessions/",
            need = 1,
            branch = true,
        },
        config = function(_, opts)
            require("persistence").setup(opts)

            local wk = require("which-key")
            wk.add({
                { "<leader>S", group = "Session" },
            })

            vim.keymap.set("n", "<leader>Ss", function()
                require("persistence").load()
            end, { desc = "Restore Session" })

            vim.keymap.set("n", "<leader>Sl", function()
                require("persistence").load({ last = true })
            end, { desc = "Restore Last Session" })

            vim.keymap.set("n", "<leader>Sd", function()
                require("persistence").stop()
            end, { desc = "Don't Save Session" })
        end,
    },
}
