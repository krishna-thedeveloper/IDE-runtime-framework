# Git Plugins

## Gitsigns (`lua/plugins/git.lua`)

- **Plugin:** `lewis6991/gitsigns.nvim`
- **Purpose:** Git decorations in the sign column and blame annotations.
- **Why:** Essential for day-to-day git workflow: see what changed, stage hunks, blame lines.
- **Alternatives:** `vim-fugitive` (broader scope, heavier), `git-messenger.vim`.

### Configuration

Configured via `managers/git/init.lua`:

```lua
signs = {
  add = { text = "+" },
  change = { text = "~" },
  delete = { text = "_" },
  topdelete = { text = "‾" },
  changedelete = { text = "~" },
},
current_line_blame = true,
current_line_blame_opts = {
  virt_text = true,
  virt_text_pos = "eol",
  delay = 800,
},
attach_to_untracked = true,
watch_gitdir = { interval = 1000, follow_files = true },
```

### Features

- **Sign column**: Shows git status (add/modify/delete) in the gutter.
- **Current line blame**: Virtual text at end-of-line showing who last modified the line (800ms delay).
- **Hunk navigation**: Jump to next/previous git change.
- **Stage/reset**: Stage or reset hunks (normal mode and visual selection).
- **Blame**: Full blame information via `:Gitsigns blame` or keymaps.
- **Toggle**: Toggle line blame visibility and deleted lines.

### Keymaps

Defined in `managers/git/init.lua` via `on_attach`:

| Key | Action |
|---|---|
| `]c` | Next git change |
| `[c` | Previous git change |
| `<leader>gs` | Stage hunk |
| `<leader>gr` | Reset hunk |
| `<leader>gS` | Stage buffer |
| `<leader>gR` | Reset buffer |
| `<leader>gp` | Preview hunk |
| `<leader>gb` | Blame line |
| `<leader>gB` | Full blame |
| `<leader>tb` | Toggle line blame |
| `<leader>td` | Toggle deleted lines |

## Persistence (`lua/plugins/persistence.lua`)

- **Plugin:** `folke/persistence.nvim`
- **Purpose:** Session management — saves and restores the editor state across restarts.
- **Why:** Seamless session handling with Lazy.nvim integration. Only saves when at least 1 buffer is open.
- **Alternatives:** `possession.nvim`, `resession.nvim`, native `:mksession`.

### Features

- Auto-saves on `BufReadPre`.
- Branch-aware sessions (different sessions per git branch).
- Manual load, last session load, and stop-saving commands.

### Keymaps

| Key | Action |
|---|---|
| `<leader>Ss` | Restore session |
| `<leader>Sl` | Restore last session |
| `<leader>Sd` | Don't save session |

---

**Up:** [Plugin System](plugin-system.md)
**See also:** [Statusline Git Components](../architecture/abstractions.md#7-statusline-layouts)
