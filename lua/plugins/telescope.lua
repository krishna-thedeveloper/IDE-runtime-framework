return {
    {
        url = "nvim-telescope/telescope.nvim",
        trigger = { require = "telescope" },
        category = "picker",
        dependencies = { "nvim-lua/plenary.nvim" },
        enabled = function()
            return require("managers.picker").get_active_name() == "telescope"
        end,
        config = function()
            local telescope = require("telescope")

            telescope.setup({
                defaults = {
                    prompt_prefix = "  ",
                    selection_caret = "> ",

                    layout_config = {
                        horizontal = {
                            preview_width = 0.55,
                        },
                    },

                    sorting_strategy = "ascending",
                    layout_strategy = "horizontal",

                    file_ignore_patterns = {
                        "node_modules",
                        ".git",
                        "dist",
                        "build",
                        "target",
                        ".next",
                    },
                },

                pickers = {
                    find_files = {
                        hidden = true,
                    },
                    live_grep = {
                        additional_args = function()
                            return { "--hidden" }
                        end,
                    },
                },

                extensions = {
                    fzf = {
                        fuzzy = true,
                        override_generic_sorter = true,
                        override_file_sorter = true,
                        case_mode = "smart_case",
                    },
                },
            })

            pcall(telescope.load_extension, "fzf")
        end,
    },

    {
        url = "nvim-telescope/telescope-fzf-native.nvim",
        build = "make",
    },
}
