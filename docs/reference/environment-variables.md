# Environment Variables

## Neovim Standard

| Variable | Purpose | Used By |
|---|---|---|
| `$XDG_CONFIG_HOME` | Config directory (default: `~/.config`) | Neovim, this config |
| `$XDG_DATA_HOME` | Data directory (default: `~/.local/share`) | Plugin installs, lazy.nvim |
| `$XDG_STATE_HOME` | State directory (default: `~/.local/state`) | Manager persistence files, sessions |

## Manager State Files

All stored in `vim.fn.stdpath("state")` (typically `~/.local/state/nvim/`):

| File | Manager | Contents |
|---|---|---|
| `theme.txt` | `lua/themes/init.lua` | Active theme name (e.g., `catppuccin`) |
| `density.txt` | `lua/managers/density.lua` | Density profile name (`full`, `compact`, `minimal`) |
| `focus.txt` | `lua/managers/focus.lua` | Focus mode state (`0` or `1`) |
| `notifications.txt` | `lua/managers/notifications.lua` | Notification preset (`rich`, `minimal`, `native`) |
| `completion.txt` | `lua/managers/completion/init.lua` | Active completion adapter (`blink_cmp`) |
| `picker.txt` | `lua/managers/picker/init.lua` | Active picker adapter (`telescope`, `snacks`) |
| `sessions/` | `lua/plugins/persistence.lua` | Session save files |

---

**Previous:** [Globals](globals.md)
