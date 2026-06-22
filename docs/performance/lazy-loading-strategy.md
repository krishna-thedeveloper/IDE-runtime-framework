# Lazy Loading Strategy

## Decision Tree

Every plugin's loading strategy is decided by answering these questions:

1. **Is it needed for syntax highlighting or indentation?** → `lazy = false` (treesitter).
2. **Is it needed on file open?** → `event = { "BufReadPre", "BufNewFile" }` (format, lint, persistence).
3. **Is it a pure UI enhancement?** → `event = "VeryLazy"` (statusline, bufferline, indent, which-key, notifications).
4. **Is it triggered by a command?** → `cmd = "CommandName"` (trouble, oil).
5. **Is it triggered by keypress?** → `keys = { ... }` (debug).
6. **Is it a fallback/alternative system?** → `lazy = true` (telescope, snacks picker — loaded by adapter dispatch).
7. **Is it a theme that's not active?** → `lazy = true` (all non-primary themes).

## Trigger Reference

| Event | When it fires | Appropriate for |
|---|---|---|
| `VeryLazy` | Shortly after startup (~100ms) | Purely cosmetic plugins |
| `BufReadPre` | Before a file is read | Setup that must happen before file opens |
| `BufNewFile` | When creating a new file | Same as BufReadPre |
| `InsertEnter` | When entering insert mode | Completion, auto-pairs |
| `CmdlineEnter` | When entering command mode | Command-line enhancements |
| `UIEnter` | When UI initializes | One-time UI setup |

## Priority System

Priority determines load order for non-lazy plugins:

| Priority | Load Order | Used by |
|---|---|---|
| `1000` | First | Colorschemes (must load before other highlights) |
| default (50) | After priority plugins | nvim-treesitter |

## Dependency Chain Loading

When a plugin is triggered, Lazy.nvim loads its dependencies first:

```lua
-- trouble.nvim has no dependencies (standalone)
-- nvim-dap has dependencies: nvim-dap-ui, nvim-nio
-- blink.cmp has dependencies: LuaSnip, friendly-snippets
-- lspconfig has dependencies: mason-lspconfig
-- heirline has dependencies: nvim-web-devicons
-- bufferline has dependencies: nvim-web-devicons
-- noice has dependencies: nvim-notify, nui.nvim
-- telescope has dependencies: plenary.nvim
```

## FileType Loading (Potential Future Use)

FileType-based loading could be used for language-specific plugins. Currently not used, but available:

```lua
{
  "someone/markdown-preview.nvim",
  ft = "markdown",
}
```

---

**Previous:** [Startup Optimization](startup-optimization.md)
