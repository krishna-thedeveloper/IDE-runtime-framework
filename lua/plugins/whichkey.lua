return {
    url = "folke/which-key.nvim",
    on_lazy = true,
    config = function()
        local wk = require("which-key")
        wk.setup({
            preset = "modern",
            icons = {
                group = "",
            },
        })
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
}
