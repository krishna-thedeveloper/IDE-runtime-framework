return {
    {
        "akinsho/bufferline.nvim",
        version = "*",
        event = "VeryLazy",
        dependencies = { "nvim-tree/nvim-web-devicons" },
        keys = {
            { "<leader>bp", "<cmd>BufferLineTogglePin<CR>", desc = "Toggle Pin" },
            { "<leader>bP", "<cmd>BufferLineGroupClose<CR>", desc = "Close Buffer Group" },
            { "<leader>br", "<cmd>BufferLineCloseRight<CR>", desc = "Close Right" },
            { "<leader>bl", "<cmd>BufferLineCloseLeft<CR>", desc = "Close Left" },
            { "<leader>bd", "<cmd>bd<CR>", desc = "Delete Buffer" },
            { "<S-h>", "<cmd>BufferLineCyclePrev<CR>", desc = "Prev Buffer" },
            { "<S-l>", "<cmd>BufferLineCycleNext<CR>", desc = "Next Buffer" },
            { "[b", "<cmd>BufferLineCyclePrev<CR>", desc = "Prev Buffer" },
            { "]b", "<cmd>BufferLineCycleNext<CR>", desc = "Next Buffer" },
        },
        opts = {
            options = {
                mode = "buffers",
                offsets = {
                    {
                        filetype = "neo-tree",
                        text = "File Explorer",
                        highlight = "Directory",
                        separator = true,
                    },
                },
                numbers = "none",
                buffer_close_icon = "",
                modified_icon = "",
                close_icon = "",
                left_trunc_marker = "",
                right_trunc_marker = "",
                separator_style = "slant",
                show_buffer_close_icons = false,
                show_close_icon = false,
                show_tab_indicators = true,
                persist_buffer_sort = true,
                max_name_length = 24,
                max_prefix_length = 15,
                enforce_regular_tabs = true,
                always_show_bufferline = true,
                diagnostics = "nvim_lsp",
                diagnostics_update_in_insert = false,
                diagnostics_update_on_event = true,
                diagnostics_indicator = function(count, level, _)
                    local icon = level:match("error") and " " or " "
                    return count > 0 and icon or ""
                end,
                color_icons = true,
                indicator = {
                    style = "underline",
                },
            },
        },
        config = function(_, opts)
            require("bufferline").setup(opts)
        end,
    },
}
