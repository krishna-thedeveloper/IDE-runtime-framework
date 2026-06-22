return {
    {
        "rcarriga/nvim-notify",
        event = "VeryLazy",
        opts = {
            timeout = 3000,
            max_height = function()
                return math.floor(vim.o.lines * 0.75)
            end,
            max_width = function()
                return math.floor(vim.o.columns * 0.75)
            end,
            stages = "fade_in_slide_out",
            render = "default",
            icons = {
                ERROR = "",
                WARN = "",
                INFO = "",
                DEBUG = "",
                TRACE = "✎",
            },
        },
    },

    {
        "folke/noice.nvim",
        event = "VeryLazy",
        dependencies = {
            "rcarriga/nvim-notify",
            "MunifTanjim/nui.nvim",
        },
        opts = function()
            local notifications = require("managers.notifications")
            local name = notifications.get_active_name()
            local preset = notifications.get_preset(name)
            return preset and preset.opts or notifications.base_opts
        end,
        config = function(_, opts)
            require("noice").setup(opts)
        end,
    },
}
