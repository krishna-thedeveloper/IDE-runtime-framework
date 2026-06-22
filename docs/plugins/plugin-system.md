# Plugin System

## Overview

Plugins are managed exclusively by [Lazy.nvim](https://github.com/folke/lazy.nvim). Each plugin spec lives in its own file under `lua/plugins/`. Lazy.nvim auto-discovers these files when `require("lazy").setup("plugins")` is called — no manual import is needed.

## Spec Structure

Every plugin file returns a table of Lazy.nvim spec tables:

```lua
-- lua/plugins/example.lua
return {
  {
    "author/plugin-name",
    lazy = true,              -- (default) only load when triggered
    event = "VeryLazy",       -- or "BufReadPre", "InsertEnter", etc.
    keys = { ... },           -- lazy keymaps
    cmd = "CommandName",      -- lazy commands
    ft = "filetype",          -- lazy filetype
    dependencies = { ... },   -- ensure these load first
    opts = { ... },           -- options table (passed to config)
    config = function(_, opts) -- setup function
      require("plugin").setup(opts)
    end,
  },
}
```

## Categories

| Category | Files | Count |
|---|---|---|
| UI | `bufferline.lua`, `dashboard.lua`, `indent.lua`, `notify.lua`, `statusline.lua`, `whichkey.lua` | 6 |
| Editing | `editor.lua`, `completion.lua`, `treesitter.lua` | 3 |
| Navigation | `picker.lua`, `telescope.lua` | 2 |
| Search | `telescope.lua`, `picker.lua` | 2 |
| Git | `git.lua` | 1 |
| LSP | `lsp/init.lua`, `lsp/mason.lua`, `lsp/lspconfig.lua`, `lsp/servers.lua` | 4 |
| Debug | `debug.lua` | 1 |
| Code Quality | `formatting.lua`, `linting.lua`, `trouble.lua` | 3 |
| Session | `persistence.lua` | 1 |
| Themes | `colorschemes.lua` | 1 |
| **Total** | | **19 files** |

## Loading Dispatch

```mermaid
flowchart LR
    A[lazy.setup plugins] --> B[Process spec files]
    B --> C{Has config fn?}
    C -->|Yes| D[Does config call a manager?]
    D -->|Yes| E[Manager.setup opts]
    D -->|No| F[Direct plugin setup]
    C -->|No| G{Uses opts table?}
    G -->|Yes| H[Lazy auto-calls<br/>require(plugin).setup(opts)]
    G -->|No| I[Default plugin init]
```

## Configuration Delegation Pattern

Several plugin specs delegate their configuration to managers rather than configuring directly. This adds an abstraction layer and makes the plugin replaceable:

| Plugin | Delegates to | File |
|---|---|---|
| `conform.nvim` | `managers.format.setup(opts)` | `lua/plugins/formatting.lua:29` |
| `nvim-lint` | `managers.lint.setup(opts)` | `lua/plugins/linting.lua:12` |
| `gitsigns.nvim` | `managers.git.setup()` | `lua/plugins/git.lua:5` |
| `nvim-lspconfig` | `managers.lsp.setup()` | `lua/plugins/lsp/lspconfig.lua:8` |
| `heirline.nvim` | `statusline.set_layout("full")` | `lua/plugins/statusline.lua:7` |
| `noice.nvim` | (delegates to notifications manager for opts) | `lua/plugins/notify.lua:33` |

## Plugin Groups

Related plugins are grouped in directories. Currently, only `lua/plugins/lsp/` uses this pattern:

```
lua/plugins/lsp/
├── init.lua           # Aggregates: returns { mason(), lspconfig() }
├── mason.lua          # mason.nvim + mason-lspconfig.nvim
├── lspconfig.lua      # nvim-lspconfig
└── servers.lua        # Server definitions (pure data, no spec)
```

The `init.lua` file combines sub-modules:

```lua
return {
    require("plugins.lsp.mason"),
    require("plugins.lsp.lspconfig"),
}
```

---

**Next:** [UI Plugins](ui.md)
**See also:** [Adding a Plugin](../development/adding-a-plugin.md), [Dependency Graph](../architecture/dependency-graph.md)
