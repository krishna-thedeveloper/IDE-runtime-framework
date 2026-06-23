# Startup Sequence

## Full Trace

```
Neovim process starts
  │
  ├── nvim reads init.lua from config directory
  │
  ├── [1] require("core.options")
  │     ├── vim.opt.number = true
  │     ├── vim.opt.relativenumber = true
  │     ├── vim.opt.expandtab = true, shiftwidth = 4, tabstop = 4
  │     ├── vim.opt.wrap = false
  │     ├── vim.opt.ignorecase = true, smartcase = true
  │     ├── vim.opt.cursorline = true
  │     ├── vim.opt.splitbelow = true, splitright = true
  │     ├── vim.opt.scrolloff = 8
  │     ├── vim.opt.termguicolors = true
  │     ├── vim.g.mapleader = " "
  │     ├── vim.g.maplocalleader = "\\"
  │     ├── vim.opt.foldmethod = "expr"
  │     ├── vim.opt.foldexpr = "v:lua.vim.treesitter.foldexpr()"
  │     └── vim.opt.foldlevel = 99
  │
  ├── [2] require("core.keymaps")
  │     ├── require("themes")
  │     │     ├── Discover theme files in lua/themes/
  │     │     ├── Restore active theme from state/theme.txt
  │     │     ├── Register keymaps: <leader>tc, <leader>ts, <leader>st
  │     │     └── Register ColorScheme autocmds
  │     │
  │     ├── require("managers.density")
  │     │     ├── Restore density from state/density.txt
  │     │     ├── Register keymaps: <leader>uc, <leader>sd
  │     │     └── Subscribe to focus_changed event
  │     │
  │     ├── require("managers.focus")
  │     │     ├── Restore focus state from state/focus.txt
  │     │     ├── Register keymap: <leader>z
  │     │     └── Subscribe to events (ember)
  │     │
  │     ├── require("managers.notifications")
  │     │     ├── Restore notification preset from state/notifications.txt
  │     │     ├── Register keymaps: <leader>nn, <leader>sn
  │     │     └── Subscribe to notifications_apply event
  │     │
  │     ├── require("managers.completion")
  │     │     ├── Discover adapters in managers/completion/adapters/
  │     │     ├── Restore active adapter from state/completion.txt
  │     │     ├── Register keymaps: <leader>cp, <leader>sc
  │     │     └── Default: blink_cmp
  │     │
  │     ├── require("managers.picker")
  │     │     ├── Discover adapters in managers/picker/adapters/
  │     │     ├── Restore active adapter from state/picker.txt
  │     │     ├── Register keymaps: <leader>fp, <leader>sp
  │     │     └── Default: telescope
  │     │
  │     └── Register global keymaps:
  │           ├── <leader>w  → :update
  │           ├── <leader>q  → :q
  │           ├── <leader>ff → picker.find_files
  │           ├── <leader>fg → picker.live_grep
  │           ├── <leader>fb → picker.buffers
  │           ├── <leader>fo → picker.oldfiles
  │           ├── <leader>fh → picker.help_tags
  │           ├── <leader>gf → picker.git_files
  │           └── <leader>gc → picker.git_commits
  │
  ├── [3] require("core.autocmds")
  │     └── TextYankPost → vim.highlight.on_yank()
  │
  ├── [4] require("config.plugin_manager")
  │     ├── Compute lazypath = stdpath("data") .. "/lazy/lazy.nvim"
  │     ├── If not exists: git clone folke/lazy.nvim --filter=blob:none --branch=stable
  │     ├── vim.opt.rtp:prepend(lazypath)
  │     └── require("lazy").setup("plugins")
  │           ├── Scan lua/plugins/ for spec files
  │           ├── Process each spec file (loads lua/plugins/*.lua)
  │           ├── Build plugin dependency graph
  │           ├── Install missing plugins
  │           ├── Load non-lazy plugins:
  │           │     ├── nvim-treesitter (lazy = false)
  │           │     └── Active colorscheme plugin (priority = 1000)
  │           └── Setup lazy-loading triggers for remaining:
  │                 ├── Event handlers (VeryLazy, BufReadPre, etc.)
  │                 ├── Lazy keymaps (debug keys, etc.)
  │                 └── Lazy commands (Trouble, Oil, etc.)
  │
  └── Neovim ready for input
        │
        ├── [vim.schedule] Density restore (if not "full")
        ├── [vim.schedule] Notification restore (if not "rich")
        ├── [UIEnter] Treesitter parser installation (async)
        │
        └── [VeryLazy] UI plugins load:
              ├── heirline.nvim → statusline.set_layout("full")
              ├── bufferline.nvim
              ├── indent-blankline.nvim
              ├── which-key.nvim
              ├── noice.nvim → managers.notifications.get_preset()
              └── nvim-notify
```

## Key Design Decisions

1. **Managers load in core/keymaps.lua, not at plugin time** — this ensures they are available immediately for keymap registration without waiting for Lazy.nvim to initialize.

2. **State restoration happens at module require time** — each manager reads its state file and restores its last-known state synchronously.

3. **Visual state restoration is deferred** — density and notification presets that differ from defaults are applied on `vim.schedule()` to avoid competing with Lazy.nvim's UI setup.

4. **Treesitter parser installation is deferred to UIEnter** — this avoids blocking the initial render with parser compilation.

---

**Up:** [Workflows](workflows/startup-sequence.md)
