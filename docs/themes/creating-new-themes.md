# Creating New Themes

## Adding a New Theme Entry

1. Create a file in `lua/themes/` (e.g., `lua/themes/oxocarbon.lua`).

2. Return a table of variant entries:

```lua
-- lua/themes/oxocarbon.lua
return {
  {
    name = "oxocarbon",
    plugin = "oxocarbon.nvim",     -- optional
    group = "oxocarbon",            -- optional (for lazy-load optimization)
    apply = function()
      vim.cmd.colorscheme("oxocarbon")
    end,
  },
}
```

3. Restart Neovim. The theme is auto-discovered and available via `<leader>tc` / `<leader>st`.

## Multi-Variant Themes

For themes with multiple variants (e.g., mocha/latte, dark/light):

```lua
local variants = {
  { name = "nightfox",       style = "nightfox",  is_light = false },
  { name = "dayfox",         style = "dayfox",    is_light = true  },
  { name = "dawnfox",        style = "dawnfox",   is_light = true  },
}

local entries = {}
for _, variant in ipairs(variants) do
  local v = variant
  table.insert(entries, {
    name = v.name,
    plugin = "nightfox.nvim",
    group = "nightfox",
    apply = function()
      require("nightfox").setup({ style = v.style })
      vim.cmd.colorscheme(v.style)
    end,
  })
end

return entries
```

## Plugin Spec Registration

If the theme plugin isn't already registered in `lua/plugins/colorschemes.lua`, add it:

```lua
{
  "EdenEast/nightfox.nvim",
  lazy = active_group ~= "nightfox",
  priority = 1000,
  config = delegate("nightfox"),
}
```

The `delegate` function ensures the theme is only applied when it's the active theme:

```lua
local function delegate(group)
  return function()
    local entry = theme.get_theme(theme.get_active_theme())
    if entry and entry.group == group then
      entry.apply()
    end
  end
end
```

## Updating the Light Variants Table

Set the `is_light` flag on each variant entry in your theme file.
This is used by theme setup functions to adjust options like
`transparent_background` for light vs dark variants.

## Testing Your Theme

1. Switch to it: `<leader>st` or `:lua require("managers.theme").apply("nightfox")`.
2. Verify the statusline colors adapt correctly (palette auto-extracts).
3. Test switching to another theme and back.
4. Verify plugin highlights (Telescope, WhichKey, BufferLine, etc.) are preserved.

---

**Previous:** [Switching Themes](switching-themes.md)
**Up:** [Themes](theme-system.md)
