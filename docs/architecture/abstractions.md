# Abstractions

This document describes every abstraction layer in the configuration.

## 1. Event Bus (`managers/events.lua`)

A minimal pub/sub system that decouples managers from each other.

```lua
-- Subscribe
events.on("focus_changed", function(data) ... end)

-- Emit
events.emit("focus_changed", { active = true })
```

**Events used:**

| Event | Emitter | Listeners |
|---|---|---|
| `focus_changed` | `managers/focus.lua` | `managers/density.lua` (defer visual changes when focus mode active) |
| `density_changed` | `managers/density.lua` | (extensible) |
| `notifications_apply` | `managers/density.lua` | `managers/notifications.lua` |

---

## 2. Picker Adapter System (`managers/picker/`)

Swappable file-finding and search interface.

### Interface

Each adapter must expose:

```lua
{
  label = string,                    -- Display name
  find_files = function(...),        -- File finder
  live_grep = function(...),         -- Content search
  buffers = function(...),           -- Buffer list
  oldfiles = function(...),          -- Recent files
  help_tags = function(...),         -- Help tag search
  git_files = function(...),         -- Git-tracked files
  git_commits = function(...),       -- Git log
  references = function(...),        -- LSP references (optional)
  cleanup = function()?,             -- Post-action cleanup (optional)
}
```

### Implementations

| Name | File | Backend |
|---|---|---|
| `telescope` | `lua/managers/picker/adapters/telescope.lua` | Telescope.nvim |
| `snacks` | `lua/managers/picker/adapters/snacks.lua` | Snacks.nvim picker |

### How it works

1. `managers/picker/init.lua` auto-discovers adapters in `lua/managers/picker/adapters/` at `require` time.
2. Each adapter registers via `M.register(name, adapter)`.
3. The manager creates proxy functions (`M.find_files`, `M.live_grep`, etc.) that delegate to the active adapter.
4. `M.use(name)` switches adapters at runtime (supports cleanup of previous adapter's modules).

---

## 3. Completion Adapter System (`managers/completion/`)

Swappable completion engines.

### Interface

```lua
{
  label = string,                                -- Display name
  get_capabilities = function() -> table,         -- LSP capabilities
}
```

### Implementations

| Name | File | Backend |
|---|---|---|
| `blink_cmp` | `lua/managers/completion/adapters/blink_cmp.lua` | blink.cmp |

### How it works

1. Adapters auto-discovered in `lua/managers/completion/adapters/`.
2. `M.get_capabilities()` returns the active adapter's LSP capabilities, used by `managers/lsp/init.lua`.
3. `M.use(name)` switches engines (LSP capabilities are re-applied, engine swap requires session restart for full effect).

---

## 4. Density Profiles (`managers/density.lua`)

UI density presets that coordinate multiple UI subsystems simultaneously.

```lua
profiles = {
  full = { statusline = "full", bufferline = true, indent = true, noice = "rich" },
  compact = { statusline = "compact", bufferline = true, indent = true, noice = "minimal" },
  minimal = { statusline = "minimal", bufferline = false, indent = false, noice = "native" },
}
```

### Effects of each profile:

| Profile | Statusline | Bufferline | Indent Guides | Notifications |
|---|---|---|---|---|
| Full | All components | Visible | Enabled | Rich (noice full) |
| Compact | Basic components | Visible | Enabled | Minimal (reduced noice) |
| Minimal | File name + ruler | Hidden | Disabled | Native (noice disabled) |

### Used by:
- Focus mode (`managers/focus.lua`) overrides to minimal.
- Persisted across sessions via `state/density.txt`.

---

## 5. Notification Presets (`managers/notifications.lua`)

Three levels of notification UI richness, implemented as diffs over a base noice.nvim config.

```lua
deltas = {
  rich = { opts = {} },                                      -- Full noice
  minimal = { opts = { messages = false, ... } },             -- Reduced noice
  native = { opts = { cmdline = false, notify = false, ... } }, -- No noice at all
}
```

### Preserved state:
- Saved to `state/notifications.txt`.
- Restored on startup via `vim.schedule`.
- Density profiles can trigger notification preset changes via the event bus.

---

## 6. Theme System (`lua/themes/init.lua`)

Auto-discovers themes with variant support, plugin highlight preservation, and palette extraction.

### Theme entry format:

```lua
{
  name = "catppuccin-latte",     -- Unique identifier
  plugin = "catppuccin",         -- Lazy.nvim plugin name to load on switch
  group = "catppuccin",          -- Colorscheme group for lazy-load optimization
  apply = function() end,        -- Function to activate the theme
}
```

### Key features:

- **Plugin highlight preservation**: Before applying a new theme, all plugin-specific highlight groups (Telescope, WhichKey, BufferLine, etc.) are saved and restored after theme application.
- **Palette extraction**: After theme application, `M.update_palette()` reads back highlight groups and updates a shared palette used by the statusline.
- **Persistence**: Active theme saved to `state/theme.txt`.

---

## 7. Statusline Layouts (`lua/statusline/init.lua`)

Composable Heirline statusline with density-aware layouts.

### Components:

| Component | Purpose |
|---|---|
| `ViMode` | Modal indicator with colored background |
| `FileIcon` | Filetype icon from nvim-web-devicons |
| `FileName` | Relative file path |
| `FileModified` | Modified indicator (blue dot) |
| `FileReadOnly` | Read-only indicator (lock icon) |
| `GitBranch` | Current git branch |
| `GitChanges` | Git diff stats (+ ~ -) |
| `Diagnostics` | Error/warning/hint counts |
| `LSPActive` | Connected LSP client names |
| `FileEncoding` | File encoding |
| `Ruler` | Line:Column position |
| `Scrollbar` | Scroll percentage |

---

## 8. Manager Module Pattern

Every manager follows the same pattern:

```lua
local M = {}

-- State persistence
local state_dir = vim.fn.stdpath("state")
local state_file = state_dir .. "/module_name.txt"

-- State management
function M.get_active_name() ... end
function M.save(name) ... end

-- User actions
function M.cycle() ... end     -- Rotate through options
function M.select() ... end    -- vim.ui.select picker
function M.apply(name) ... end -- Set specific option
function M.setup() ... end     -- Called by plugin config

-- Keymaps registered at module level
vim.keymap.set("n", "<leader>xx", M.cycle, { desc = "Cycle X" })
vim.keymap.set("n", "<leader>sx", M.select, { desc = "Select X" })

return M
```

This pattern is used by: `density.lua`, `focus.lua`, `notifications.lua`, `completion/init.lua`, `picker/init.lua`.

---

**Previous:** [Dependency Graph](dependency-graph.md)
**Up:** [Architecture](overview.md)
