local M = {}

local state_dir = vim.fn.stdpath("state")
local theme_file = state_dir .. "/theme.txt"

local default_palette = {
    red = "#e06c75", green = "#98c379", yellow = "#e5c07b",
    blue = "#61afef", purple = "#c678dd", cyan = "#56b6c2",
    white = "#abb2bf", gray = "#5c6370", dark_bg = "#282c34",
}

M.palette = vim.deepcopy(default_palette)

local function to_hex(color)
    if type(color) == "number" then
        return string.format("#%06x", color)
    end
    return color
end

function M.update_palette()
    local hl = vim.api.nvim_get_hl
    M.palette.red = to_hex(hl(0, { name = "DiagnosticError" }).fg or default_palette.red)
    M.palette.green = to_hex(hl(0, { name = "DiagnosticOk" }).fg or default_palette.green)
    M.palette.yellow = to_hex(hl(0, { name = "DiagnosticWarn" }).fg or default_palette.yellow)
    M.palette.blue = to_hex(hl(0, { name = "Function" }).fg or default_palette.blue)
    M.palette.purple = to_hex(hl(0, { name = "Special" }).fg or default_palette.purple)
    M.palette.cyan = to_hex(hl(0, { name = "@type" }).fg or default_palette.cyan)
    M.palette.white = to_hex(hl(0, { name = "Normal" }).fg or default_palette.white)
    M.palette.gray = to_hex(hl(0, { name = "Comment" }).fg or default_palette.gray)
    M.palette.dark_bg = to_hex(hl(0, { name = "NormalFloat" }).bg or default_palette.dark_bg)
end

local PLUGIN_PREFIXES = {
    "Telescope", "WhichKey", "BufferLine", "Buffer",
    "Noice", "Notify", "Dap", "DapUI", "Trouble",
    "GitSigns", "Mini", "Oil", "Heirline", "Snacks",
    "BlinkCmp",
}

local function save_plugin_groups()
    local saved = {}
    for _, prefix in ipairs(PLUGIN_PREFIXES) do
        local ok, matches = pcall(vim.fn.getcompletion, prefix, "highlight")
        if ok and matches then
            for _, name in ipairs(matches) do
                local hl = vim.api.nvim_get_hl(0, { name = name, link = true })
                if hl and (hl.link or hl.fg or hl.bg) then
                    saved[name] = hl
                end
            end
        end
    end
    return saved
end

local function restore_plugin_groups(saved)
    for name, hl in pairs(saved) do
        if vim.fn.hlexists(name) == 0 then
            if hl.link then
                pcall(vim.api.nvim_set_hl, 0, name, { link = hl.link })
            else
                pcall(vim.api.nvim_set_hl, 0, name, hl)
            end
        end
    end
end

M.themes = {}

local function discover_themes()
    local ok, files = pcall(vim.fn.readdir, vim.fn.stdpath("config") .. "/lua/themes")
    if not ok or not files then
        return
    end
    for _, file in ipairs(files) do
        local mod = file:match("^(.*)%.lua$")
        if mod and mod ~= "init" then
            local ok_load, entries = pcall(require, "themes." .. mod)
            if ok_load and type(entries) == "table" then
                for _, entry in ipairs(entries) do
                    if entry.name and entry.apply then
                        table.insert(M.themes, entry)
                    end
                end
            end
        end
    end
end

discover_themes()
table.sort(M.themes, function(a, b) return a.name < b.name end)

function M.get_theme(name)
    for _, t in ipairs(M.themes) do
        if t.name == name then
            return t
        end
    end
    return nil
end

function M.get_active_theme()
    local f = io.open(theme_file, "r")
    if f then
        local name = f:read("*l")
        f:close()
        name = name and vim.trim(name) or ""
        if name ~= "" then
            return name
        end
    end
    return "catppuccin"
end

function M.get_active_group()
    local name = M.get_active_theme()
    local entry = M.get_theme(name)
    return entry and entry.group or "catppuccin"
end

local light_variants = {
    ["tokyonight-day"] = true,
    ["kanagawa-lotus"] = true,
    ["catppuccin-latte"] = true,
    ["everforest-light"] = true,
    ["github-light"] = true,
    ["github-light-high-contrast"] = true,
}

function M.is_light_variant(name)
    return light_variants[name] or false
end

function M.save_theme(name)
    local theme = M.get_theme(name)
    if not theme then
        return
    end
    vim.fn.mkdir(state_dir, "p")
    local f = io.open(theme_file, "w")
    if f then
        f:write(name)
        f:close()
    end
end

function M.load_theme(name)
    local theme = M.get_theme(name)
    if not theme then
        return
    end

    for i, t in ipairs(M.themes) do
        if t.name == name then
            current_idx = i
            break
        end
    end

    local saved_groups = save_plugin_groups()

    pcall(require("lazy").load, { plugins = theme.plugin })

    theme.apply()

    restore_plugin_groups(saved_groups)

    M.update_palette()
    vim.api.nvim_exec_autocmds("ColorScheme", { pattern = vim.g.colors_name })

    vim.cmd("redrawstatus!")

    pcall(vim.api.nvim_set_hl, 0, "NotifyBackground", { link = "NormalFloat" })

    vim.notify("Theme: " .. name, vim.log.levels.INFO)
    M.save_theme(name)
end

function M.show_current_theme()
    local name = M.get_active_theme()
    vim.notify("Current theme: " .. name, vim.log.levels.INFO)
end

local current_idx = nil

function M.get_current_index()
    if not current_idx then
        local name = M.get_active_theme()
        for i, t in ipairs(M.themes) do
            if t.name == name then
                current_idx = i
                return i
            end
        end
        current_idx = 1
    end
    return current_idx
end

function M.cycle()
    current_idx = (M.get_current_index() % #M.themes) + 1
    M.load_theme(M.themes[current_idx].name)
end

vim.keymap.set("n", "<leader>tc", M.cycle, { desc = "Cycle theme" })
vim.keymap.set("n", "<leader>ts", M.show_current_theme, { desc = "Show current theme" })

vim.api.nvim_create_autocmd("ColorScheme", {
    group = vim.api.nvim_create_augroup("themes_palette", { clear = true }),
    callback = M.update_palette,
})

vim.api.nvim_create_autocmd("ColorScheme", {
    group = vim.api.nvim_create_augroup("themes_links", { clear = true }),
    callback = function()
        pcall(vim.api.nvim_set_hl, 0, "NotifyBackground", { link = "NormalFloat" })
    end,
})

return M
