return {
    {
        "folke/snacks.nvim",
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
        },
    },
}
