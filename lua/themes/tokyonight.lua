local function on_highlights(hl, c)
    hl.NormalFloat = { bg = c.bg_dark }
    hl.FloatBorder = { bg = c.bg_dark, fg = c.blue }
    hl.NormalSB = { bg = c.bg_dark }
end

local variants = {
    { name = "tokyonight", style = "night", sidebars_floats = "dark", is_light = false },
    { name = "tokyonight-storm", style = "storm", sidebars_floats = "dark", is_light = false },
    { name = "tokyonight-moon", style = "moon", sidebars_floats = "dark", is_light = false },
    { name = "tokyonight-day", style = "day", sidebars_floats = "light", is_light = true },
}

local entries = {}
for _, variant in ipairs(variants) do
    local v = variant
    table.insert(entries, {
        name = v.name,
        plugin = "tokyonight.nvim",
        group = "tokyonight",
        is_light = v.is_light,
        apply = function()
            require("tokyonight").setup({
                style = v.style,
                transparent = not v.is_light,
                terminal_colors = true,
                styles = {
                    comments = { italic = true },
                    sidebars = v.sidebars_floats,
                    floats = v.sidebars_floats,
                },
                on_highlights = on_highlights,
            })
            vim.cmd.colorscheme(v.name)
        end,
    })
end

return entries
