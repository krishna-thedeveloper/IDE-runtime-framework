local variants = {
    { name = "everforest",       background = "hard",   is_light = false },
    { name = "everforest-soft",  background = "soft",   is_light = false },
    { name = "everforest-light", background = "medium", is_light = true  },
}

local entries = {}
for _, variant in ipairs(variants) do
    local v = variant
    table.insert(entries, {
        name = v.name,
        plugin = "everforest",
        group = "everforest",
        is_light = v.is_light,
        apply = function()
            vim.g.everforest_background = v.background
            vim.g.everforest_better_performance = 1
            vim.g.everforest_transparent_background = v.is_light and 0 or 1
            vim.g.everforest_enable_italic = 1
            vim.g.everforest_disable_italic_comment = 0
            if v.is_light then
                vim.o.background = "light"
            end
            vim.cmd.colorscheme("everforest")
        end,
    })
end

return entries
