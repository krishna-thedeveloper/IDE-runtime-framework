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
                { "<leader>t", group = "Theme" },
                { "<leader>u", group = "UI" },
                { "<leader>n", group = "Notifications" },
                { "<leader>d", group = "Debug" },
                { "<leader>x", group = "Trouble" },
                { "<leader>S", group = "Session" },
                { "<leader>s", group = "Select" },
            })
        end,
    },
}
