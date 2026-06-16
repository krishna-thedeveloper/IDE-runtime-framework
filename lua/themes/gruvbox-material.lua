local variants = {
    { name = "gruvbox-material",        contrast = "medium" },
    { name = "gruvbox-material-soft",   contrast = "soft"   },
    { name = "gruvbox-material-hard",   contrast = "hard"   },
}

local entries = {}
for _, variant in ipairs(variants) do
    local v = variant
    table.insert(entries, {
        name = v.name,
        plugin = "gruvbox-material",
        group = "gruvbox-material",
        apply = function()
            vim.g.gruvbox_material_background = v.contrast
            vim.g.gruvbox_material_better_performance = 1
            vim.g.gruvbox_material_transparent_background = 1
            vim.g.gruvbox_material_italic_keywords = 1
            vim.g.gruvbox_material_dim_inactive = 0
            vim.cmd.colorscheme("gruvbox-material")
        end,
    })
end

return entries
