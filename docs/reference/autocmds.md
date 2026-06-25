# Autocommands

## Global Autocmds

Defined in `lua/core/autocmds.lua`:

| Event | Pattern | Purpose |
|---|---|---|
| `TextYankPost` | (none) | Highlight yanked text |

## Manager Autocmds

| Event | Source | Purpose |
|---|---|---|
| `ColorScheme` | `lua/managers/theme.lua:191` | Update palette after theme switch |
| `ColorScheme` | `lua/managers/theme.lua:195` | Re-link `NotifyBackground` |
| `ColorScheme` | `lua/plugins/bufferline.lua:59` | Re-setup bufferline highlights |
| `ColorScheme` | `lua/plugins/indent.lua:47` | Re-set indent-blankline highlights |

## LSP Autocmds

| Event | Source | Purpose |
|---|---|---|
| `LspAttach` | `lua/managers/lsp/init.lua:6` | Set up buffer-local LSP keymaps and config |

## Linting Autocmds

| Events | Source | Purpose |
|---|---|---|
| `BufWritePost`, `BufReadPost`, `InsertLeave` | `lua/managers/lint/init.lua:17` | Trigger linting with debounce |

## Treesitter Autocmds

| Event | Source | Purpose |
|---|---|---|
| `UIEnter` (once) | `lua/plugins/treesitter.lua:36` | Auto-install missing parsers |
| `FileType` | `lua/plugins/treesitter.lua:52` | Enable treesitter per filetype |

---

**Previous:** [Commands](commands.md)
**Next:** [Options](options.md)
