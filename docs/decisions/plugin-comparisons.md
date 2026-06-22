# Plugin Comparisons

## Picker: Telescope vs Snacks

| Criterion | Telescope | Snacks Picker |
|---|---|---|
| Maturity | Very mature (released 2020) | Newer (2024) |
| Extensions ecosystem | Rich (fzf, grep, undo, etc.) | Emerging |
| Performance | Good (fzf-native for speed) | Excellent (built-in fuzzy) |
| Frecent sorting | Extension needed | Built-in |
| Default UI | Horizontal with preview | Vertical by default |
| Configuration | Verbose | Concise |
| Memory | Higher (~20 modules) | Lower |
| `vim.ui.select` replacement | No | Yes (`ui_select = true`) |

## Statusline: Heirline vs Lualine

| Criterion | Heirline | Lualine |
|---|---|---|
| Component model | Pure Lua table composition | Pre-defined slots |
| Conditional rendering | Built-in (condition function) | Limited |
| Dynamic styling | Per-component `hl` function | Fixed per-mode |
| Complexity | Higher (more flexible) | Lower (simpler) |
| Density/focus integration | Natural (layouts are tables) | Workaround needed |

## Completion: blink.cmp vs nvim-cmp

| Criterion | blink.cmp | nvim-cmp |
|---|---|---|
| Speed | Faster (modern architecture) | Slower |
| Config verbosity | Concise | Verbose |
| Ghost text | Built-in | Extension needed |
| LSP capabilities integration | Clean API | Manual merging |
| Maturity | Newer (stable 1.0) | Very mature |
| Community adoption | Growing rapidly | Currently dominant |

## Notifications: noice.nvim vs raw

| Criterion | noice.nvim | Native Neovim |
|---|---|---|
| Visual polish | Highly polished | Basic |
| Cmdline replacement | Yes | No |
| LSP progress UI | Yes | No |
| Config complexity | Higher | None |
| Preset system (rich/minimal/native) | Via manager | N/A |
| Performance | Overhead on each message | Minimal |

## Git: gitsigns.nvim vs fugitive

| Criterion | Gitsigns | Fugitive |
|---|---|---|
| Inline decorations | Yes (sign column, blame) | No |
| Scope | Git status display | Full git porcelain |
| Complexity | Lower | Higher |
| Used for | Signs, blame, hunk ops | Commits, diffs, branching |

## Session: persistence.nvim vs native

| Criterion | persistence.nvim | :mksession |
|---|---|---|
| Auto-save/restore | Yes | Manual |
| Branch awareness | Yes | No |
| Integration with Lazy | Built-in | None |
| Configuration | Minimal | Full control |

---

**Previous:** [Why This Architecture](why-this-architecture.md)
**Next:** [Migration History](migration-history.md)
