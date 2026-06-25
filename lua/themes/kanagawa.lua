local variants = {
    { name = "kanagawa", style = "wave", is_light = false },
    { name = "kanagawa-dragon", style = "dragon", is_light = false },
    { name = "kanagawa-lotus", style = "lotus", is_light = true },
}

local function make_opts(v)
    local opts = {
        compile = false,
        undercurl = true,
        commentStyle = { italic = true },
        functionStyle = {},
        keywordStyle = { italic = true },
        statementStyle = { bold = true },
        typeStyle = {},
        variableStyle = {},
        transparent = not v.is_light,
        dimInactive = false,
        terminalColors = true,
    }

    if v.is_light then
        opts.commentStyle = {}
    end

    opts.colors = {
        theme = {
            all = {
                ui = {
                    bg_dim = "#1f1f28",
                    bg_gutter = "#1f1f28",
                },
            },
        },
    }

    opts.overrides = function(colors)
        local theme = colors.theme
        return {
            NormalFloat = { bg = theme.ui.bg_dim },
            FloatBorder = { bg = theme.ui.bg_dim, fg = theme.syn.blue },
            NormalSB = { bg = theme.ui.bg_dim },
        }
    end

    return opts
end

local entries = {}
for _, variant in ipairs(variants) do
    local v = variant
    table.insert(entries, {
        name = v.name,
        plugin = "kanagawa.nvim",
        group = "kanagawa",
        is_light = v.is_light,
        apply = function()
            require("kanagawa").setup(make_opts(v))
            vim.cmd.colorscheme("kanagawa")
            vim.g.colors_name = v.name
        end,
    })
end

return entries
