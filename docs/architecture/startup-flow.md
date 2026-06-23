# Startup Flow

## Sequence Diagram

```mermaid
sequenceDiagram
    participant N as Neovim
    participant I as init.lua
    participant O as core/options.lua
    participant K as core/keymaps.lua
    participant A as core/autocmds.lua
    participant PM as config/plugin_manager.lua
    participant AD as Adapter (lazy/pckr/mini_deps/vim_pack)
    participant P as plugins/*.lua
    participant M as managers/
    participant S as statusline/

    N->>I: Start Neovim
    I->>O: require("core.options")
    O-->>I: Set Neovim options, leaders
    I->>K: require("core.keymaps")
    K->>M: require managers (themes, density, focus, notifications, completion, picker)
    K-->>I: Register core keymaps
    I->>A: require("core.autocmds")
    A-->>I: Register global autocmds
    I->>PM: require("config.plugin_manager")
    PM->>PM: Read adapter name (lazy / pckr / mini_deps / vim_pack)
    PM->>AD: Bootstrap selected adapter
    AD->>AD: Clone backend if missing
    AD->>P: require("plugins") — load all spec files
    P-->>AD: Return plugin specs table
    AD->>AD: setup(specs) — adapter processes triggers
    AD-->>I: Setup complete
    I-->>N: Ready for user input

    Note over P,M: Plugins load lazily on events/keys/commands

    N->>S: On VeryLazy event
    S-->>N: Heirline statusline rendered
```

## Step-by-Step

### 1. `init.lua` (5 lines)

```lua
require("core.options")
require("core.keymaps")
require("core.autocmds")
require("config.plugin_manager")
```

This is the single entry point. It loads modules in dependency order:

1. **Options** — sets `vim.opt` values, `vim.g.mapleader`, and `vim.g.maplocalleader`. No dependencies.
2. **Keymaps** — registers global keybindings and **loads all manager modules** that define their own keymaps (themes, density, focus, notifications, completion, picker). These managers register keymaps at `require` time.
3. **Autocmds** — registers `TextYankPost` highlight. Standalone.
4. **Plugin Manager** — reads the selected adapter from `config/plugin_manager.lua`, bootstraps the backend if missing, then loads all plugin specs.

### 2. `core/options.lua`

Sets core Neovim options:

- `number`, `relativenumber` — line numbers.
- `expandtab`, `shiftwidth`, `tabstop` — 4-space indentation.
- `ignorecase`, `smartcase` — case-insensitive search with smart casing.
- `cursorline` — highlight current line.
- `splitbelow`, `splitright` — intuitive split behavior.
- `scrolloff` — keep 8 lines of context.
- `termguicolors` — truecolor support.
- `foldmethod`, `foldexpr` — Treesitter-based folding.
- `foldlevel` — start with all folds open.

Also sets `mapleader` to `<Space>` and `maplocalleader` to `\`.

### 3. `core/keymaps.lua`

Registers global keymaps and triggers manager loading:

```lua
require("themes")              -- registers theme keymaps (<leader>tc, <leader>ts, <leader>st)
require("managers.density")     -- registers density keymaps (<leader>uc, <leader>sd)
require("managers.focus")       -- registers focus keymaps (<leader>z)
require("managers.notifications") -- registers notification keymaps (<leader>nn, <leader>sn)
require("managers.completion")  -- registers completion keymaps (<leader>cp, <leader>sc)
```

Then registers the file picker maps:

```lua
local picker = require("managers.picker")
vim.keymap.set("n", "<leader>ff", picker.find_files, ...)
```

### 4. `core/autocmds.lua`

Registers `TextYankPost` autocmd to highlight yanked text.

### 5. `config/plugin_manager.lua`

The adapter bootstrap process:

1. Reads the adapter name (one of `"lazy"`, `"pckr"`, `"mini_deps"`, `"vim_pack"`).
2. Requires the corresponding adapter from `lua/managers/plugin_manager/`.
3. The adapter bootstraps its backend (clone if missing, set up runtime path).
4. Calls `setup("plugins")` — the adapter discovers all files in `lua/plugins/` and processes them.

For each adapter, the bootstrap path differs:

| Adapter | Backend path | Clone URL |
|---|---|---|
| `lazy` | `stdpath("data") .. "/lazy/lazy.nvim"` | `folke/lazy.nvim` (stable branch) |
| `pckr` | `stdpath("data") .. "/pckr/pckr.nvim"` | `lewis6991/pckr.nvim` |
| `mini_deps` | `stdpath("data") .. "/mini.deps"` | `echasnovski/mini.deps` |
| `vim_pack` | (built-in, no clone) | N/A |

### 6. Plugin Loading (Adapter)

The adapter processes all plugin specs from `lua/plugins/`. Universal spec fields include:

- **lazy** — whether to lazy-load (default: `true`).
- **event** — Neovim events that trigger loading.
- **keys** — keymaps that trigger loading.
- **cmd** — commands that trigger loading.
- **ft** — filetypes that trigger loading.
- **priority** — for non-lazy plugins, load order priority.
- **condition** — function that gates loading at runtime.
- **dependencies** — ensure dependencies load first.

See [Lazy Loading](lazy-loading.md) for details.

### 7. Manager Setup

When plugins _do_ load (triggered by events/keys/commands), their `config()` functions call into managers:

- `conform.nvim` → `managers.format.setup()`
- `nvim-lint` → `managers.lint.setup()`
- `gitsigns.nvim` → `managers.git.setup()`
- `nvim-lspconfig` → `managers.lsp.setup()`
- `heirline.nvim` → `statusline.set_layout("full")`

### 8. Deferred Operations

Several operations happen on `vim.schedule()` to avoid blocking startup:

- **Density restore** (`managers/density.lua:192`): if the user had a non-default density preset, it's applied after startup.
- **Notification restore** (`managers/notifications.lua:265`): if the user had a non-rich notification preset, it's applied after startup.
- **Treesitter install** (`plugins/treesitter.lua:36`): missing parsers are installed after `UIEnter`.

---

**Previous:** [Repository Structure](repository-structure.md)
**Next:** [Lazy Loading](lazy-loading.md)
**See also:** [Abstractions](abstractions.md)
