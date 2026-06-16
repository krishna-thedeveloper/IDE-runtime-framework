local theme = require("themes")
local active_group = theme.get_active_group()

local function delegate(group)
    return function()
        local entry = theme.get_theme(theme.get_active_theme())
        if entry and entry.group == group then
            entry.apply()
        end
    end
end

return {
    {
        "navarasu/onedark.nvim",
        lazy = active_group ~= "onedark",
        priority = 1000,
        config = delegate("onedark"),
    },
    {
        "folke/tokyonight.nvim",
        lazy = active_group ~= "tokyonight",
        priority = 1000,
        config = delegate("tokyonight"),
    },
    {
        "rebelot/kanagawa.nvim",
        lazy = active_group ~= "kanagawa",
        priority = 1000,
        config = delegate("kanagawa"),
    },
    {
        "catppuccin/nvim",
        lazy = active_group ~= "catppuccin",
        priority = 1000,
        name = "catppuccin",
        config = delegate("catppuccin"),
    },
    {
        "sainnhe/everforest",
        lazy = active_group ~= "everforest",
        priority = 1000,
        config = delegate("everforest"),
    },
    {
        "sainnhe/gruvbox-material",
        lazy = active_group ~= "gruvbox-material",
        priority = 1000,
        config = delegate("gruvbox-material"),
    },
    {
        "projekt0n/github-nvim-theme",
        lazy = active_group ~= "github",
        priority = 1000,
        name = "github-theme",
        config = delegate("github"),
    },
}
