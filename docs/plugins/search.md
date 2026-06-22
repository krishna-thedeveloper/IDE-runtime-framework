# Search Plugins

## Telescope (`lua/plugins/telescope.lua`)

- **Plugin:** `nvim-telescope/telescope.nvim`
- **Purpose:** Fuzzy finder for files, grep, buffers, help tags, git, and more.
- **Why:** The most mature and extensible fuzzy finder for Neovim. Extensive ecosystem of extensions.
- **Alternatives:** Snacks picker (also used via adapter), fzf-lua.
- **Lazy loading:** `lazy = true` (loaded on first picker invocation via manager dispatch).
- **Dependencies:** `plenary.nvim`, `telescope-fzf-native.nvim`.

### Configuration

```lua
defaults = {
  prompt_prefix = "  ",
  selection_caret = "> ",
  layout_config = { horizontal = { preview_width = 0.55 } },
  sorting_strategy = "ascending",
  layout_strategy = "horizontal",
  file_ignore_patterns = { "node_modules", ".git", "dist", "build", "target", ".next" },
}
```

### Extensions

- **telescope-fzf-native.nvim**: Native FZF sorter for performance. Built with `make` on install. Overrides generic and file sorters.

### Picker Configs

```lua
pickers = {
  find_files = { hidden = true },
  live_grep = { additional_args = { "--hidden" } },
}
```

## Snacks Picker (`lua/plugins/picker.lua`)

- **Plugin:** `folke/snacks.nvim` (picker module)
- **Purpose:** Alternative fuzzy finder with a different UI and behavior.
- **Why:** Integrated into the Snacks ecosystem. Can be swapped with Telescope at runtime.
- **Configuration:**

```lua
picker = {
  enabled = true,
  ui_select = true,       -- Replaces vim.ui.select
  prompt = "❯ ",
  layout = { preset = "vertical" },
  formatters = { file = { filename_first = true, truncate = "left" } },
  matcher = { cwd_bonus = true, frecency = true },
  sources = {
    files = { hidden = true },
    grep = { hidden = true },
    buffers = { sort_lastused = true },
    git_files = { untracked = true },
  },
}
```

### Key Differences from Telescope

| Feature | Telescope | Snacks Picker |
|---|---|---|
| File finding | `find_files` | `files` |
| Content search | `live_grep` | `grep` |
| Recent files | `oldfiles` | `recent` |
| Help tags | `help_tags` | `help` |
| Git log | `git_commits` | `git_log` |
| FZF native | Yes (extension) | Built-in |
| Frecent sorting | No (requires extension) | Built-in |

## Runtime Switching

The picker adapter system (`managers/picker`) allows switching between Telescope and Snacks at runtime:

```lua
:lua require("managers.picker").cycle()
```

Or with the keymap `<leader>fp`.

Both pickers share the same keybindings:

| Key | Action |
|---|---|
| `<leader>ff` | Find files |
| `<leader>fg` | Live grep |
| `<leader>fb` | Find buffers |
| `<leader>fo` | Find old files |
| `<leader>fh` | Help tags |
| `<leader>gf` | Git files |
| `<leader>gc` | Git commits |

---

**Up:** [Plugin System](plugin-system.md)
**See also:** [Search Flow](../workflows/search-flow.md), [Picker Adapter System](../architecture/abstractions.md#2-picker-adapter-system-managerspicker)
