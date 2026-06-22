# Globals

## User-Defined Globals

This configuration avoids global Lua variables. No `_G` pollution.

## Vim Global Variables

| Variable | Value | Set In |
|---|---|---|
| `vim.g.mapleader` | `" "` | `lua/core/options.lua:22` |
| `vim.g.maplocalleader` | `"\\"` | `lua/core/options.lua:23` |

## Plugin Globals (Set by Theme Configs)

| Variable | Set In | When |
|---|---|---|
| `vim.g.colors_name` | Various theme `apply()` functions | After colorscheme command |
| `vim.g.everforest_background` | `lua/themes/everforest.lua:15` | On everforest apply |
| `vim.g.everforest_better_performance` | `lua/themes/everforest.lua:16` | On everforest apply |
| `vim.g.everforest_transparent_background` | `lua/themes/everforest.lua:17` | On everforest apply |
| `vim.g.everforest_enable_italic` | `lua/themes/everforest.lua:18` | On everforest apply |
| `vim.g.gruvbox_material_background` | `lua/themes/gruvbox-material.lua:15` | On gruvbox apply |
| `vim.g.gruvbox_material_better_performance` | `lua/themes/gruvbox-material.lua:16` | On gruvbox apply |
| `vim.g.gruvbox_material_transparent_background` | `lua/themes/gruvbox-material.lua:17` | On gruvbox apply |

---

**Previous:** [Options](options.md)
**Next:** [Environment Variables](environment-variables.md)
