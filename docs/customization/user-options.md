# User Options

## Overview

This configuration does not yet have a dedicated user options module that allows overriding without modifying source files. This is a planned feature.

## Current Customization Points

### Options

`lua/core/options.lua` contains all Neovim options. Edit this file to change:

- Indentation (shiftwidth, tabstop, expandtab).
- Line numbers (number, relativenumber).
- Search behavior (ignorecase, smartcase).
- Scroll behavior (scrolloff).
- Splitting (splitbelow, splitright).
- Folding (foldmethod, foldexpr).
- Leaders (mapleader, maplocalleader).

### Manager Settings

Each manager has state files that persist user preferences:

| Setting | File | Default |
|---|---|---|
| Active theme | `state/theme.txt` | `catppuccin` |
| Density profile | `state/density.txt` | `full` |
| Notification preset | `state/notifications.txt` | `rich` |
| Active picker | `state/picker.txt` | `telescope` |
| Active completion | `state/completion.txt` | `blink_cmp` |
| Focus mode | `state/focus.txt` | `0` |

These are modified at runtime via keymaps (`<leader>uc`, `<leader>nn`, `<leader>fp`, etc.).

### Plugin Options

Each plugin spec file has an `opts` table that can be modified:

```lua
-- lua/plugins/treesitter.lua
opts = {
  ensure_installed = { "lua", "javascript", ... },
  highlight = { enable = true },
  indent = { enable = true },
}
```

## Future: User Config Override

Planned architecture for user overrides:

```lua
-- lua/config/user.lua (not yet implemented)
local M = {}

function M.setup()
  -- User overrides go here
end

return M
```

This would be called after all configurations are loaded, allowing users to override any setting without modifying the core files.

---

**Next:** [Overriding Configurations](overriding-configurations.md)
