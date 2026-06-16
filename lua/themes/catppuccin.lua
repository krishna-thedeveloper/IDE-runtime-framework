local variants = {
    { name = "catppuccin",          flavour = "mocha",     is_light = false },
    { name = "catppuccin-macchiato", flavour = "macchiato", is_light = false },
    { name = "catppuccin-frappe",   flavour = "frappe",    is_light = false },
    { name = "catppuccin-latte",    flavour = "latte",     is_light = true  },
}

local entries = {}
for _, variant in ipairs(variants) do
    local v = variant
    table.insert(entries, {
        name = v.name,
        plugin = "catppuccin",
        group = "catppuccin",
        apply = function()
            require("catppuccin").setup({
                flavour = v.flavour,
                transparent_background = not v.is_light,
                term_colors = true,
                dim_inactive = { enabled = false },
                styles = {},
                integrations = {
                    telescope = true,
                    which_key = true,
                    notify = true,
                    noice = true,
                    native_lsp = { enabled = true },
                    gitsigns = true,
                    indent_blankline = { enabled = true },
                    mini = false,
                },
                compile_path = vim.fn.stdpath("cache") .. "/catppuccin",
                custom_highlights = function(colors)
                    return {
                        NormalFloat = { bg = colors.mantle },
                        FloatBorder = { bg = colors.mantle, fg = colors.blue },
                        NormalSB = { bg = colors.mantle },
                    }
                end,
            })
            vim.cmd.colorscheme("catppuccin")
        end,
    })
end

return entries
