return {
    url = "folke/snacks.nvim",
    trigger = { require = "snacks" },
    opts = {
        picker = {
            enabled = true,
            ui_select = true,
            prompt = "❯ ",
            layout = {
                preset = "vertical",
            },
            formatters = {
                file = {
                    filename_first = true,
                    truncate = "left",
                },
            },
            matcher = {
                cwd_bonus = true,
                frecency = true,
            },
            sources = {
                files = { hidden = true },
                grep = { hidden = true },
                buffers = { sort_lastused = true },
                git_files = { untracked = true },
                lines = {
                    layout = { preset = "ivy" },
                },
            },
            win = {
                input = {
                    keys = {
                        ["<Esc>"] = { "close", mode = { "n", "i" } },
                    },
                },
            },
        },
        dashboard = {
            enabled = true,
            preset = {
                header = [[
    __      _   _     __     ___
   / _\__ _| |_| |__  \ \   / (_)_ __ ___   __ _
   \ \/ _` | __| '_ \  \ \ / /| | '_ ` _ \ / _` |
 _\ \ (_| | |_| |_) |  \ V / | | | | | | | | (_| |
\__/\__,_|\__|_.__/    \_/  |_|_| |_| |_|\__,_|
                ]],
                keys = {
                    { icon = " ", key = "f", desc = "Find File", action = ":lua Snacks.dashboard.pick('files')" },
                    { icon = " ", key = "g", desc = "Live Grep", action = ":lua Snacks.dashboard.pick('live_grep')" },
                    { icon = " ", key = "r", desc = "Recent Files", action = ":lua Snacks.dashboard.pick('oldfiles')" },
                    { icon = " ", key = "c", desc = "Configuration", action = ":lua Snacks.dashboard.pick('files', {pattern = vim.fn.stdpath('config')})" },
                    { icon = " ", key = "s", desc = "Restore Session", action = ":lua require('persistence').load()" },
                    { icon = " ", key = "q", desc = "Quit", action = ":qa" },
                },
            },
        },
    },
}
