local theme = require("managers.theme")
local active_group = theme.get_active_group()

local function delegate(group)
    return function()
        local entry = theme.get_theme(theme.get_active_theme())
        if entry and entry.group == group then
            entry.apply()
        end
    end
end

local function theme_spec(url, group, name)
    return {
        url = url,
        on_startup = active_group == group,
        priority = 1000,
        name = name,
        config = delegate(group),
    }
end

return {
    theme_spec("navarasu/onedark.nvim", "onedark"),
    theme_spec("folke/tokyonight.nvim", "tokyonight"),
    theme_spec("rebelot/kanagawa.nvim", "kanagawa"),
    theme_spec("catppuccin/nvim", "catppuccin", "catppuccin"),
    theme_spec("sainnhe/everforest", "everforest"),
    theme_spec("sainnhe/gruvbox-material", "gruvbox-material"),
    theme_spec("projekt0n/github-nvim-theme", "github", "github-theme"),
}
