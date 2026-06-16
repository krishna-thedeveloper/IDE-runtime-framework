return {
    {
        "lewis6991/gitsigns.nvim",
        config = function()
            require("gitsigns").setup({
                signs = {
                    add = { text = "+" },
                    change = { text = "~" },
                    delete = { text = "_" },
                    topdelete = { text = "‾" },
                    changedelete = { text = "~" },
                },

                signcolumn = true,
                numhl = false,
                linehl = false,

                watch_gitdir = {
                    interval = 1000,
                    follow_files = true,
                },

                attach_to_untracked = true,

                current_line_blame = true,
                current_line_blame_opts = {
                    virt_text = true,
                    virt_text_pos = "eol",
                    delay = 800,
                    ignore_whitespace = false,
                },

                sign_priority = 6,
                update_debounce = 200,
                status_formatter = nil,

                on_attach = function(bufnr)
                    local gs = package.loaded.gitsigns
                    local map = function(mode, lhs, rhs, desc)
                        vim.keymap.set(mode, lhs, rhs, {
                            buffer = bufnr,
                            desc = desc,
                        })
                    end

                    map("n", "]c", gs.next_hunk, "Next Git Change")
                    map("n", "[c", gs.prev_hunk, "Previous Git Change")

                    map("n", "<leader>gs", gs.stage_hunk, "Stage Hunk")
                    map("n", "<leader>gr", gs.reset_hunk, "Reset Hunk")

                    map("v", "<leader>gs", function()
                        gs.stage_hunk({ vim.fn.line("."), vim.fn.line("v") })
                    end, "Stage Selected Hunk")

                    map("v", "<leader>gr", function()
                        gs.reset_hunk({ vim.fn.line("."), vim.fn.line("v") })
                    end, "Reset Selected Hunk")

                    map("n", "<leader>gS", gs.stage_buffer, "Stage Buffer")
                    map("n", "<leader>gR", gs.reset_buffer, "Reset Buffer")

                    map("n", "<leader>gp", gs.preview_hunk, "Preview Hunk")

                    map("n", "<leader>gb", gs.blame_line, "Blame Line")
                    map("n", "<leader>gB", function()
                        gs.blame_line({ full = true })
                    end, "Full Blame")

                    map("n", "<leader>tb", gs.toggle_current_line_blame, "Toggle Blame")
                    map("n", "<leader>td", gs.toggle_deleted, "Toggle Deleted Lines")
                end,
            })
        end,
    },
}
