local variants = {
    { name = "github-dark",               colorscheme = "github_dark",              is_light = false },
    { name = "github-dark-dimmed",        colorscheme = "github_dark_dimmed",       is_light = false },
    { name = "github-dark-high-contrast", colorscheme = "github_dark_high_contrast", is_light = false },
    { name = "github-light",              colorscheme = "github_light",             is_light = true  },
    { name = "github-light-high-contrast", colorscheme = "github_light_high_contrast", is_light = true  },
}

local entries = {}
for _, variant in ipairs(variants) do
    local v = variant
    table.insert(entries, {
        name = v.name,
        plugin = "github-theme",
        group = "github",
        is_light = v.is_light,
        apply = function()
            require("github-theme").setup({
                options = {
                    transparent = not v.is_light,
                },
            })
            vim.cmd.colorscheme(v.colorscheme)
        end,
    })
end

return entries
