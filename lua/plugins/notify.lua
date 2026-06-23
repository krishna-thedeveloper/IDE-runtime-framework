return {
    {
        url = "rcarriga/nvim-notify",
        trigger = { lazy = true },
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
        url = "folke/noice.nvim",
        trigger = { lazy = true },
        dependencies = {
            "rcarriga/nvim-notify",
            "MunifTanjim/nui.nvim",
        },
        config = function()
            local notifications = require("managers.notifications")
            local name = notifications.get_active_name()
            local preset = notifications.get_preset(name)
            local opts = preset and preset.opts or notifications.base_opts
            require("noice").setup(opts)
            require("managers.notifications").setup()
        end,
    },
}
