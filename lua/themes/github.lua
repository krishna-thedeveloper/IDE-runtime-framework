local variants = {
    { name = "github-dark",               colourscheme = "github_dark",              is_light = false },
    { name = "github-dark-dimmed",        colourscheme = "github_dark_dimmed",       is_light = false },
    { name = "github-dark-high-contrast", colourscheme = "github_dark_high_contrast", is_light = false },
    { name = "github-light",              colourscheme = "github_light",             is_light = true  },
    { name = "github-light-high-contrast", colourscheme = "github_light_high_contrast", is_light = true  },
}

local entries = {}
for _, variant in ipairs(variants) do
    local v = variant
    table.insert(entries, {
        name = v.name,
        plugin = "github-theme",
        group = "github",
        apply = function()
            require("github-theme").setup({
                options = {
                    transparent = not v.is_light,
                },
            })
            vim.cmd.colorscheme(v.colourscheme)
        end,
    })
end

return entries
