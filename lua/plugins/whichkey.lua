return {
    {
        "folke/which-key.nvim",
        event = "VeryLazy",
        opts = {
            preset = "modern",
            icons = {
                group = "",
            },
        },
        config = function(_, opts)
            local wk = require("which-key")
            wk.setup(opts)
            wk.add({
                { "<leader>f", group = "Find" },
                { "<leader>g", group = "Git" },
                { "<leader>c", group = "Code" },
                { "<leader>u", group = "UI" },
                { "<leader>n", group = "Notifications" },
            })
        end,
    },
}
