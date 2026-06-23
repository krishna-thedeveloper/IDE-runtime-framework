# Plugin System

## Overview

Plugins are managed by one of four swappable backends (adapters), selected via a single line in `lua/config/plugin_manager.lua`. Each plugin spec lives in its own file under `lua/plugins/`.

### Supported Adapters

| Adapter | Backend | Features |
|---|---|---|
| **lazy** (default) | [Lazy.nvim](https://github.com/folke/lazy.nvim) | Full native lazy-loading, profiling, UI dashboard |
| **pckr** | [pckr.nvim](https://github.com/lewis6991/pckr.nvim) | Native lazy-loading, semver ranges, compile-based startup |
| **mini_deps** | [mini.deps](https://github.com/echasnovski/mini.deps) | Lightweight, no external dependencies, snapshot/restore |
| **vim_pack** | Built-in `vim.pack` | Zero dependencies, uses Neovim's built-in `:packadd` |

Switch by editing the first line of `lua/config/plugin_manager.lua`:

```lua
-- Change this to "pckr", "mini_deps", or "vim_pack"
return "lazy"
```

All four adapters support the same universal spec fields (see below). Backend-specific features (e.g., Lazy.nvim's UI dashboard) are available when using that adapter.

## Spec Structure

Every plugin file returns a table of spec tables that are backend-agnostic:

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
    condition = function() return vim.g.some_condition end, -- gate loading
    priority = 1000,           -- load order (adapter-specific)
  },
}
```

## Adapter Bootstrap

When Neovim starts, `init.lua` calls `require("config.plugin_manager")`, which:

1. Reads the adapter name from the file.
2. Requires the corresponding `lua/managers/plugin_manager/adapters/<name>.lua`.
3. The adapter bootstraps its backend (clone if missing, setup runtime path).
4. Calls `setup("plugins")` — the adapter discovers all files in `lua/plugins/` and processes them.

For details, see [Plugin Manager Architecture](../architecture/plugin-manager.md).

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
    A[config/plugin_manager.lua] --> B{Select adapter}
    B -->|lazy| C[require lazy.setup plugins]
    B -->|pckr| D[require pckr.setup plugins]
    B -->|mini_deps| E[process plugins via mini.deps API]
    B -->|vim_pack| F[process plugins via packadd]
    C & D & E & F --> G[Process spec files]
    G --> H{Has config fn?}
    H -->|Yes| I[Does config call a manager?]
    I -->|Yes| J[Manager.setup opts]
    I -->|No| K[Direct plugin setup]
    H -->|No| L{Uses opts table?}
    L -->|Yes| M[Adapter auto-calls<br/>require(plugin).setup(opts)]
    L -->|No| N[Default plugin init]
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
