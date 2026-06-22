local state = require("managers.state")
local base = require("managers.base")

local default_palette = {
  red = "#e06c75", green = "#98c379", yellow = "#e5c07b",
  blue = "#61afef", purple = "#c678dd", cyan = "#56b6c2",
  white = "#abb2bf", gray = "#5c6370", dark_bg = "#282c34",
}

local discovered_items = {}
local discovered_order = {}

local theme = base.create_preset_manager({
  state_file = vim.fn.stdpath("state") .. "/theme.txt",
  desc = "theme",
  default = "catppuccin",
  items = discovered_items,
  order = discovered_order,
})

theme.palette = vim.deepcopy(default_palette)

local function to_hex(color)
  if type(color) == "number" then
    return string.format("#%06x", color)
  end
  return color
end

function theme.update_palette()
  local hl = vim.api.nvim_get_hl
  theme.palette.red = to_hex(hl(0, { name = "DiagnosticError" }).fg or default_palette.red)
  theme.palette.green = to_hex(hl(0, { name = "DiagnosticOk" }).fg or default_palette.green)
  theme.palette.yellow = to_hex(hl(0, { name = "DiagnosticWarn" }).fg or default_palette.yellow)
  theme.palette.blue = to_hex(hl(0, { name = "Function" }).fg or default_palette.blue)
  theme.palette.purple = to_hex(hl(0, { name = "Special" }).fg or default_palette.purple)
  theme.palette.cyan = to_hex(hl(0, { name = "@type" }).fg or default_palette.cyan)
  theme.palette.white = to_hex(hl(0, { name = "Normal" }).fg or default_palette.white)
  theme.palette.gray = to_hex(hl(0, { name = "Comment" }).fg or default_palette.gray)
  theme.palette.dark_bg = to_hex(hl(0, { name = "NormalFloat" }).bg or default_palette.dark_bg)
end

local PLUGIN_PREFIXES = {
  "Telescope", "WhichKey", "Buffer",
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
      local restored = {}
      if hl.link then
        restored.link = hl.link
      end
      if hl.fg then
        restored.fg = hl.fg
      end
      if hl.bg then
        restored.bg = hl.bg
      end
      pcall(vim.api.nvim_set_hl, 0, name, restored)
    end
  end
end

local function discover_themes()
  local seen = {}
  for _, rtp in ipairs(vim.api.nvim_list_runtime_paths()) do
    local theme_dir = rtp .. "/lua/themes"
    if vim.fn.isdirectory(theme_dir) == 1 then
      local ok, files = pcall(vim.fn.readdir, theme_dir)
      if ok and files then
        for _, file in ipairs(files) do
          local mod = file:match("^(.*)%.lua$")
          if mod and mod ~= "init" and not seen[mod] then
            seen[mod] = true
            local ok_load, entries = pcall(require, "themes." .. mod)
            if ok_load and type(entries) == "table" then
              for _, entry in ipairs(entries) do
                if entry.name and entry.apply then
                  theme._items[entry.name] = entry
                  table.insert(theme._order, entry.name)
                end
              end
            end
          end
        end
      end
    end
  end
end

discover_themes()
table.sort(theme._order)

theme.get_active_theme = theme.get_active_name

function theme.get_theme(name)
  return theme._items[name]
end

function theme.get_active_group()
  local name = theme.get_active_name()
  local entry = theme.get_theme(name)
  return entry and entry.group or "catppuccin"
end

function theme.show_current_theme()
  local name = theme.get_active_name()
  vim.notify("Current theme: " .. name, vim.log.levels.INFO)
end

function theme.apply(name)
  local t = theme._items[name]
  if not t then
    return
  end

  for i, n in ipairs(theme._order) do
    if n == name then
      theme._current_idx = i
      break
    end
  end

  local saved_groups = save_plugin_groups()

  pcall(require("managers.plugin_manager").load_plugin, t.plugin)

  local ok = pcall(t.apply)
  if not ok then
    return
  end

  restore_plugin_groups(saved_groups)

  vim.api.nvim_exec_autocmds("ColorScheme", { pattern = vim.g.colors_name })
  vim.cmd("redrawstatus!")
  vim.notify("Theme: " .. name, vim.log.levels.INFO)
  theme.save(name)
end

function theme.select()
  local items = vim.tbl_map(function(n)
    return n
  end, theme._order)
  local current = theme.get_active_name()
  vim.ui.select(items, {
    prompt = "Select theme",
    format_item = function(item)
      local display = item:gsub("^.", string.upper):gsub("%-(.)", function(c)
        return " " .. c:upper()
      end)
      if item == current then
        return display .. "  ●"
      end
      return display
    end,
  }, function(choice)
    if choice then
      theme.apply(choice)
    end
  end)
end

vim.keymap.set("n", "<leader>tc", theme.cycle, { desc = "Cycle theme" })
vim.keymap.set("n", "<leader>ts", theme.show_current_theme, { desc = "Show current theme" })
vim.keymap.set("n", "<leader>st", theme.select, { desc = "Select theme" })

vim.api.nvim_create_autocmd("ColorScheme", {
  group = vim.api.nvim_create_augroup("themes_palette", { clear = true }),
  callback = function()
    theme.update_palette()
    pcall(vim.api.nvim_set_hl, 0, "NotifyBackground", { link = "NormalFloat" })
  end,
})

return theme
