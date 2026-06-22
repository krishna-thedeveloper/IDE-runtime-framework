# Architecture Overview

This document describes the high-level architecture of the Neovim configuration. It is designed as a **framework**, not a collection of scattered plugin configs.

## Design Tenets

1. **Separation of concerns** — Core, Plugins, Managers, Themes, and UI are distinct layers with defined responsibilities.
2. **Runtime swappability** — Major subsystems (pickers, completion, notifications, UI density) can be switched without restart.
3. **Framework over config** — Abstractions like `managers.picker`, `managers.completion`, `managers.events` provide stable APIs that plugins implement against.
4. **Lazy by default** — No plugin loads without a specific event, keymap, or command trigger unless it is absolutely required at startup.

## Layer Diagram

```
┌──────────────────────────────────────────────────────┐
│                     init.lua                          │
│         Entry point — loads core, then lazy          │
└──────────────────────┬───────────────────────────────┘
                       │
                       ▼
┌──────────────────────────────────────────────────────┐
│                     core/                             │
│  options.lua  │  keymaps.lua  │  autocmds.lua        │
│  (Neovim opts,│  (global maps,│  (global autocmds)   │
│   leaders)    │   managers)   │                       │
└───────────────┴───────┬───────┴───────────────────────┘
                        │
                        ▼
┌──────────────────────────────────────────────────────┐
│                   config/lazy.lua                     │
│  Lazy.nvim bootstrap → require("plugins")            │
└──────────────────────┬───────────────────────────────┘
                       │
                       ▼
┌──────────────────────────────────────────────────────┐
│                    plugins/                           │
│  Plugin specs with lazy-loading triggers              │
│  (events, keys, commands, filetypes)                  │
├──────────────────────────────────────────────────────┤
│  Each plugin → config() → may call a manager          │
│  e.g., conform.nvim config → managers.format.setup()  │
└──────────────────────┬───────────────────────────────┘
                       │
                       ▼
┌──────────────────────────────────────────────────────┐
│                    managers/                          │
│  Abstraction layer between plugins and the rest       │
│                                                       │
│  picker/  │  completion/  │  lsp/  │  format/        │
│  lint/    │  git/         │  events.lua              │
│  density.lua  │  focus.lua  │  notifications.lua     │
└──────────────────────────────────────────────────────┘
```

## Module Dependency Graph

```
init.lua
  ├── core/options.lua      (standalone)
  ├── core/keymaps.lua      → themes, managers.{density, focus, notifications, completion, picker}
  ├── core/autocmds.lua     (standalone)
  └── config/lazy.lua
        └── plugins/*.lua
              ├── plugins/lsp/init.lua
              │     ├── plugins/lsp/mason.lua
              │     └── plugins/lsp/lspconfig.lua → managers/lsp/init.lua
              │                                          ├── managers/completion (for capabilities)
              │                                          └── plugins/lsp/servers.lua
              ├── plugins/formatting.lua → managers/format/init.lua
              ├── plugins/linting.lua    → managers/lint/init.lua
              ├── plugins/git.lua        → managers/git/init.lua
              ├── plugins/statusline.lua → statusline/init.lua
              ├── plugins/dashboard.lua  (snacks.nvim)
              ├── plugins/telescope.lua  → managers/picker/adapters/telescope.lua
              ├── plugins/picker.lua     (snacks.nvim picker config)
              ├── plugins/completion.lua (blink.cmp) → managers/completion/adapters/blink_cmp.lua
              ├── plugins/notify.lua     → managers/notifications.lua
              ├── plugins/debug.lua
              ├── plugins/trouble.lua
              ├── plugins/whichkey.lua
              ├── plugins/bufferline.lua
              ├── plugins/treesitter.lua
              ├── plugins/editor.lua
              ├── plugins/colorschemes.lua
              ├── plugins/persistence.lua
              └── plugins/indent.lua
```

## Key Abstractions

| Abstraction | File | Purpose |
|---|---|---|
| Event Bus | `lua/managers/events.lua` | Simple pub/sub for cross-manager communication |
| Picker Adapter | `lua/managers/picker/` | Abstract picker interface (Telescope / Snacks) |
| Completion Adapter | `lua/managers/completion/` | Abstract completion interface (blink.cmp) |
| Density Profiles | `lua/managers/density.lua` | UI density presets (full / compact / minimal) |
| Focus Mode | `lua/managers/focus.lua` | Minimal editing mode |
| Notification Presets | `lua/managers/notifications.lua` | Rich / Minimal / Native notification levels |
| Theme System | `lua/themes/init.lua` | Theme discovery, switching, palette extraction |
| Statusline Layouts | `lua/statusline/init.lua` | Composable Heirline layouts per density |

---

**Next:** [Repository Structure](repository-structure.md)
**See also:** [Startup Flow](startup-flow.md), [Abstractions](abstractions.md), [Dependency Graph](dependency-graph.md)
