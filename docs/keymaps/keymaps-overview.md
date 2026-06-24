# Keymaps Overview

## Philosophy

- **Leader key** is `<Space>`.
- **Local leader** is `\`.
- Keymaps are organized by **prefix groups** which are registered in `which-key.nvim` for discoverability.
- Global keymaps are in `lua/core/keymaps.lua`. Plugin-specific keymaps are defined in their respective plugin spec files or manager files.
- Keymaps use `desc` attribute extensively for which-key display.

## Leader Prefix Groups

| Prefix | Group | Configured In |
|---|---|---|
| `<leader>f` | Find | `core/keymaps.lua` (routed through picker manager) |
| `<leader>g` | Git | `managers/git/init.lua` |
| `<leader>c` | Code | `managers/lsp/init.lua`, `managers/format/init.lua` |
| `<leader>u` | UI | `managers/density.lua`, `managers/focus.lua` |
| `<leader>n` | Notifications | `managers/notifications.lua` |
| `<leader>d` | Debug | `plugins/debug.lua` |
| `<leader>x` | Trouble | `plugins/trouble.lua` |
| `<leader>S` | Session | `plugins/persistence.lua` |
| `<leader>s` | Select | Various managers (theme, density, notifications, completion, picker) |
| `<leader>t` | Theme | `managers/theme.lua` |
| `<leader>b` | Buffer | `plugins/bufferline.lua` |

## Complete Keymap Reference

### General

| Key | Action | Source |
|---|---|---|
| `<leader>w` | Save file (`:update`) | `core/keymaps.lua:9` |
| `<leader>q` | Close window (`:q`) | `core/keymaps.lua:10` |

### Find / Search (Picker)

| Key | Action | Source |
|---|---|---|
| `<leader>ff` | Find files | `core/keymaps.lua:12` |
| `<leader>fg` | Live grep | `core/keymaps.lua:13` |
| `<leader>fb` | Find buffers | `core/keymaps.lua:14` |
| `<leader>fo` | Find old files | `core/keymaps.lua:15` |
| `<leader>fh` | Help tags | `core/keymaps.lua:16` |
| `<leader>gf` | Git files | `core/keymaps.lua:17` |
| `<leader>gc` | Git commits | `core/keymaps.lua:18` |
| `<leader>fp` | Cycle picker (Telescope/Snacks) | `managers/picker/init.lua:139` |
| `<leader>sp` | Select picker | `managers/picker/init.lua:140` |

### Git

| Key | Action | Source |
|---|---|---|
| `]c` | Next git change | `managers/git/init.lua:52` |
| `[c` | Previous git change | `managers/git/init.lua:53` |
| `<leader>gs` | Stage hunk | `managers/git/init.lua:55` |
| `<leader>gr` | Reset hunk | `managers/git/init.lua:56` |
| `<leader>gS` | Stage buffer | `managers/git/init.lua:66` |
| `<leader>gR` | Reset buffer | `managers/git/init.lua:67` |
| `<leader>gp` | Preview hunk | `managers/git/init.lua:69` |
| `<leader>gb` | Blame line | `managers/git/init.lua:71` |
| `<leader>gB` | Full blame | `managers/git/init.lua:72` |
| `<leader>tb` | Toggle line blame | `managers/git/init.lua:76` |
| `<leader>td` | Toggle deleted lines | `managers/git/init.lua:77` |

### Code / LSP

| Key | Action | Source |
|---|---|---|
| `gd` | Go to definition | `managers/lsp/init.lua:11` |
| `gr` | Find references | `managers/lsp/init.lua:12` |
| `gi` | Go to implementation | `managers/lsp/init.lua:13` |
| `K` | Hover documentation | `managers/lsp/init.lua:14` |
| `<leader>rn` | Rename symbol | `managers/lsp/init.lua:22` |
| `<leader>ca` | Code action | `managers/lsp/init.lua:23` |
| `[d` | Previous diagnostic | `managers/lsp/init.lua:26` |
| `]d` | Next diagnostic | `managers/lsp/init.lua:27` |
| `<leader>e` | Diagnostic float | `managers/lsp/init.lua:28` |
| `<leader>cf` | Format file | `managers/format/init.lua:7` |
| `<leader>cp` | Cycle completion engine | `managers/completion/init.lua:120` |
| `<leader>sc` | Select completion engine | `managers/completion/init.lua:121` |

### UI / Density

| Key | Action | Source |
|---|---|---|
| `<leader>uc` | Cycle UI density (Full/Compact/Minimal) | `managers/density.lua:187` |
| `<leader>sd` | Select UI density | `managers/density.lua:188` |
| `<leader>z` | Toggle focus mode | `managers/focus.lua:67` |

### Notifications

| Key | Action | Source |
|---|---|---|
| `<leader>nn` | Cycle notification preset | `managers/notifications.lua:262` |
| `<leader>sn` | Select notification preset | `managers/notifications.lua:263` |

### Debug

| Key | Action | Source |
|---|---|---|
| `<leader>db` | Toggle breakpoint | `plugins/debug.lua:9` |
| `<leader>dB` | Conditional breakpoint | `plugins/debug.lua:10` |
| `<leader>dc` | Continue | `plugins/debug.lua:12` |
| `<leader>dC` | Run to cursor | `plugins/debug.lua:13` |
| `<leader>do` | Step over | `plugins/debug.lua:14` |
| `<leader>di` | Step into | `plugins/debug.lua:15` |
| `<leader>dO` | Step out | `plugins/debug.lua:16` |
| `<leader>dr` | Toggle REPL | `plugins/debug.lua:17` |
| `<leader>du` | Toggle DAP UI | `plugins/debug.lua:18` |
| `<leader>dh` | DAP hover | `plugins/debug.lua:19` |

### Trouble

| Key | Action | Source |
|---|---|---|
| `<leader>xx` | Toggle diagnostics | `plugins/trouble.lua:6` |
| `<leader>xX` | Toggle buffer diagnostics | `plugins/trouble.lua:7` |
| `<leader>cs` | Toggle symbols | `plugins/trouble.lua:8` |
| `<leader>cl` | Toggle LSP references | `plugins/trouble.lua:9` |
| `<leader>xL` | Toggle location list | `plugins/trouble.lua:10` |
| `<leader>xQ` | Toggle quickfix list | `plugins/trouble.lua:11` |

### Session

| Key | Action | Source |
|---|---|---|
| `<leader>Ss` | Restore session | `plugins/persistence.lua:14` |
| `<leader>Sl` | Restore last session | `plugins/persistence.lua:18` |
| `<leader>Sd` | Don't save session | `plugins/persistence.lua:22` |

### Theme

| Key | Action | Source |
|---|---|---|
| `<leader>tc` | Cycle theme | `managers/theme.lua:184` |
| `<leader>ts` | Show current theme | `managers/theme.lua:185` |
| `<leader>st` | Select theme | `managers/theme.lua:186` |

### Buffer

| Key | Action | Source |
|---|---|---|
| `<leader>bp` | Toggle pin | `plugins/bufferline.lua:8` |
| `<leader>bP` | Close buffer group | `plugins/bufferline.lua:9` |
| `<leader>br` | Close buffers right | `plugins/bufferline.lua:10` |
| `<leader>bl` | Close buffers left | `plugins/bufferline.lua:11` |
| `<leader>bd` | Delete buffer | `plugins/bufferline.lua:12` |
| `<S-h>` / `[b` | Previous buffer | `plugins/bufferline.lua:13,15` |
| `<S-l>` / `]b` | Next buffer | `plugins/bufferline.lua:14,16` |

## Keymap Source Organization

| Location | Type |
|---|---|
| `lua/core/keymaps.lua` | Global leader maps (save, quit, picker actions) |
| `lua/managers/*.lua` | Manager-level keymaps (density, focus, notifications, completion, picker cycling/selection) |
| `lua/managers/theme.lua` | Theme keymaps |
| `lua/plugins/*.lua` | Plugin-specific keymaps (debug, trouble, bufferline, persistence) |
| `lua/managers/*/init.lua` | Manager setup keymaps (LSP, git, format) |

---

**Next:** [Leader Mappings](leader-mappings.md)
**See also:** [Which-Key](which-key.md)
