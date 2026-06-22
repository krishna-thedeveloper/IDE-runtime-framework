# UI Plugins

## Bufferline (`lua/plugins/bufferline.lua`)

- **Plugin:** `akinsho/bufferline.nvim`
- **Purpose:** Tab bar at the top of the editor showing open buffers.
- **Why:** More intuitive than Neovim's native tabline; supports diagnostics, pinning, and visual grouping.
- **Alternatives:** `nvim-bufferline.lua` (lighter but fewer features), native tabline.
- **Lazy loading:** `event = "VeryLazy"`
- **Dependencies:** `nvim-web-devicons`

### Features

- Slant separator style.
- Diagnostics via nvim-lsp (error/warning indicators on tabs).
- Pin, close-right, close-left, group-close operations.
- Left/right cycle via `<S-h>` / `<S-l>` or `[b` / `]b`.
- Offsets for neo-tree file explorer.
- Auto-re-setup on `ColorScheme` to maintain highlights.

### Keymaps

| Key | Action |
|---|---|
| `<leader>bp` | Toggle pin |
| `<leader>bP` | Close buffer group |
| `<leader>br` | Close buffers to the right |
| `<leader>bl` | Close buffers to the left |
| `<leader>bd` | Delete buffer |
| `<S-h>` / `[b` | Previous buffer |
| `<S-l>` / `]b` | Next buffer |

## Dashboard (`lua/plugins/dashboard.lua`)

- **Plugin:** `folke/snacks.nvim` (dashboard module)
- **Purpose:** Startup screen with ASCII header, key bindings, recent files, and last session.
- **Why:** Integrated with Snacks ecosystem, no additional plugin needed.
- **Alternatives:** `dashboard-nvim`, `alpha-nvim`.

## Indent Guides (`lua/plugins/indent.lua`)

- **Plugin:** `lukas-reineke/indent-blankline.nvim`
- **Purpose:** Vertical indent lines to visually indicate code structure.
- **Why:** Lightweight, fast, supports scope highlighting.
- **Lazy loading:** `event = "VeryLazy"`

### Features

- Scope highlighting (start/end of indent block).
- Smart indent cap (stops at end of function/block).
- Excluded filetypes: help, dashboard, neo-tree, Trouble, lazy, mason, notify, noice, oil, toggleterm, lspinfo.
- Custom highlight colors (`IblIndent`, `IblScope`).

## Notifications (`lua/plugins/notify.lua`)

Two plugins working together:

- **`rcarriga/nvim-notify`** — Notification backend.
- **`folke/noice.nvim`** — UI overlay for messages, cmdline, popupmenu, LSP progress, and more.

**Lazy loading:** Both at `event = "VeryLazy"`.

### Presets

Controlled by `managers/notifications.lua`:

| Preset | Cmdline | Messages | Popupmenu | Notify | LSP Progress | LSP Hover |
|---|---|---|---|---|---|---|
| Rich | yes | notify | nui | notify | mini | yes |
| Minimal | yes | off | nui | mini | off | yes |
| Native | off | off | off | off | off | off |

## Statusline (`lua/plugins/statusline.lua`)

- **Plugin:** `rebelot/heirline.nvim`
- **Purpose:** Highly customizable statusline built from composable components.
- **Why:** Most flexible statusline plugin; supports conditionals, dynamic styling, and easy component composition.
- **Alternatives:** `lualine.nvim` (simpler, less flexible), `feline.nvim` (unmaintained).
- **Lazy loading:** `event = "VeryLazy"`
- **Dependencies:** `nvim-web-devicons`

Full statusline implementation is in `lua/statusline/init.lua`. See [Statusline Abstraction](../architecture/abstractions.md#7-statusline-layouts).

## Which-Key (`lua/plugins/whichkey.lua`)

- **Plugin:** `folke/which-key.nvim`
- **Purpose:** Popup that shows available keymaps when you press a leader prefix.
- **Why:** Essential for discoverability of leader-based keymaps.
- **Lazy loading:** `event = "VeryLazy"`

### Group Mappings

| Prefix | Group |
|---|---|
| `<leader>f` | Find |
| `<leader>g` | Git |
| `<leader>c` | Code |
| `<leader>u` | UI |
| `<leader>n` | Notifications |
| `<leader>d` | Debug |
| `<leader>x` | Trouble |
| `<leader>S` | Session |
| `<leader>s` | Select |

## Trouble (`lua/plugins/trouble.lua`)

- **Plugin:** `folke/trouble.nvim`
- **Purpose:** Diagnostics, references, symbols, quickfix, and location list in a rich list view.
- **Why:** Better UX than native quickfix for diagnostics browsing.
- **Lazy loading:** `cmd = "Trouble"` (keymaps trigger the command).
- **Configuration:** Bottom panel, auto-open/close disabled, indent guides enabled.

### Keymaps

| Key | Action |
|---|---|
| `<leader>xx` | Toggle diagnostics |
| `<leader>xX` | Toggle buffer diagnostics |
| `<leader>cs` | Toggle symbols |
| `<leader>cl` | Toggle LSP references |
| `<leader>xL` | Toggle location list |
| `<leader>xQ` | Toggle quickfix list |

---

**Up:** [Plugin System](plugin-system.md)
