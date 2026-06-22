# Options

## Core Options

Set in `lua/core/options.lua`:

| Option | Value | Purpose |
|---|---|---|
| `number` | `true` | Show line numbers |
| `relativenumber` | `true` | Relative line numbers |
| `expandtab` | `true` | Use spaces, not tabs |
| `shiftwidth` | `4` | Indentation width |
| `tabstop` | `4` | Tab character width |
| `wrap` | `false` | No line wrapping |
| `ignorecase` | `true` | Case-insensitive search |
| `smartcase` | `true` | Smart case detection |
| `cursorline` | `true` | Highlight current line |
| `splitbelow` | `true` | New splits below |
| `splitright` | `true` | New splits right |
| `scrolloff` | `8` | Lines of context |
| `termguicolors` | `true` | Truecolor support |
| `foldmethod` | `"expr"` | Treesitter-based folding |
| `foldexpr` | `"v:lua.vim.treesitter.foldexpr()"` | Fold expression |
| `foldlevel` | `99` | Start with all folds open |

## Diagnostic Options

Set in `lua/managers/lsp/init.lua`:

| Option | Value |
|---|---|
| `virtual_text` | `{ prefix = "", source = true }` |
| `signs` | `true` |
| `underline` | `true` |
| `update_in_insert` | `false` |
| `severity_sort` | `true` |
| `float` | `{ border = "rounded", source = true }` |

## Global Variables

| Variable | Value | Purpose |
|---|---|---|
| `vim.g.mapleader` | `" "` | Leader key |
| `vim.g.maplocalleader` | `"\\"` | Local leader key |

---

**Previous:** [Autocmds](autocmds.md)
**Next:** [Globals](globals.md)
