return {
    {
        url = "saghen/blink.cmp",
        version = "1.*",
        on_require = "blink.cmp",
        dependencies = { "L3MON4D3/LuaSnip", "rafamadriz/friendly-snippets" },
        config = function()
            require("blink.cmp").setup({
                keymap = {
                    preset = "default",
                    ["<CR>"] = { "accept", "fallback" },
                },
                appearance = {
                    nerd_font_variant = "mono",
                },
                snippets = { preset = "luasnip" },
                sources = {
                    default = { "lsp", "path", "snippets", "buffer" },
                },
                completion = {
                    documentation = { auto_show = true, auto_show_delay_ms = 500 },
                    ghost_text = { enabled = true },
                    menu = {
                        auto_show = true,
                        draw = {
                            columns = {
                                { "label", "label_description", gap = 1 },
                                { "kind_icon", "kind" },
                            },
                        },
                    },
                },
            })
        end,
    },
    {
        url = "L3MON4D3/LuaSnip",
        version = "v2.*",
        on_require = "luasnip",
        build = "make install_jsregexp",
        config = function()
            require("luasnip.loaders.from_vscode").lazy_load()
            require("luasnip.loaders.from_vscode").lazy_load({
                paths = { vim.fn.stdpath("config") .. "/snippets" },
            })
        end,
    },
}
