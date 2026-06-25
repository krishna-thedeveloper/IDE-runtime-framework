return {
    url = "folke/persistence.nvim",
    trigger = {
        event = "BufReadPre",
        keymap = {
            {
                "<leader>Ss",
                function()
                    require("persistence").load()
                end,
                desc = "Restore Session",
            },
            {
                "<leader>Sl",
                function()
                    require("persistence").load({ last = true })
                end,
                desc = "Restore Last Session",
            },
            {
                "<leader>Sd",
                function()
                    require("persistence").stop()
                end,
                desc = "Don't Save Session",
            },
        },
    },
    config = function()
        require("persistence").setup({
            dir = vim.fn.stdpath("state") .. "/sessions/",
            need = 1,
            branch = true,
        })
    end,
}
