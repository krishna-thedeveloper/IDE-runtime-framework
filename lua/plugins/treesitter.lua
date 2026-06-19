return {
    {
        "nvim-treesitter/nvim-treesitter",
        lazy = false,
        build = ":TSUpdate",

        opts = {
            ensure_installed = {
                "lua",
                "javascript",
                "typescript",
                "tsx",
                "proto",
                "json",
                "yaml",
                "toml",
                "bash",
                "markdown",
                "markdown_inline",
            },

            highlight = {
                enable = true,
            },

            indent = {
                enable = true,
            },
        },

        config = function(_, opts)
            local TS = require("nvim-treesitter")

            TS.setup(opts)

            vim.api.nvim_create_autocmd("UIEnter", {
                once = true,
                callback = function()
                    local installed = TS.get_installed()
                    local to_install = {}
                    for _, lang in ipairs(opts.ensure_installed) do
                        if not vim.tbl_contains(installed, lang) then
                            table.insert(to_install, lang)
                        end
                    end
                    if #to_install > 0 then
                        pcall(TS.install, to_install, { summary = true })
                    end
                end,
            })

            vim.api.nvim_create_autocmd("FileType", {
                group = vim.api.nvim_create_augroup("treesitter_features", { clear = true }),
                callback = function(ev)
                    local lang = vim.treesitter.language.get_lang(ev.match)
                    if not lang then
                        return
                    end

                    if opts.highlight.enable ~= false then
                        pcall(vim.treesitter.start, ev.buf)
                    end
                    if opts.indent.enable ~= false then
                        vim.bo[ev.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
                    end
                end,
            })
        end,
    },
}
