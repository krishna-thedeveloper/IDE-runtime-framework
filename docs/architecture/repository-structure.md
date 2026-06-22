# Repository Structure

```
nvim/
├── init.lua                    # Entry point
├── lazy-lock.json              # Plugin version lockfile
├── lua/
│   ├── core/                   # Bootstrap layer
│   │   ├── options.lua         #   Neovim options & leaders
│   │   ├── keymaps.lua         #   Global keymaps + manager loading
│   │   └── autocmds.lua        #   Global autocommands
│   │
│   ├── config/                 # Lazy.nvim setup
│   │   └── lazy.lua            #   Bootstrap + plugin loading
│   │
│   ├── plugins/                # Lazy.nvim plugin specs
│   │   ├── bufferline.lua      #   Buffer tabs
│   │   ├── colorschemes.lua    #   Theme plugin specs
│   │   ├── completion.lua      #   blink.cmp + LuaSnip
│   │   ├── dashboard.lua       #   Snacks dashboard
│   │   ├── debug.lua           #   nvim-dap + dap-ui
│   │   ├── editor.lua          #   Comment, surround, pairs, oil
│   │   ├── formatting.lua      #   conform.nvim
│   │   ├── git.lua             #   gitsigns.nvim
│   │   ├── indent.lua          #   indent-blankline.nvim
│   │   ├── linting.lua         #   nvim-lint
│   │   ├── lsp/                #   LSP plugin group
│   │   │   ├── init.lua        #     Aggregates mason + lspconfig
│   │   │   ├── mason.lua       #     mason.nvim + mason-lspconfig
│   │   │   ├── lspconfig.lua   #     nvim-lspconfig → managers.lsp
│   │   │   └── servers.lua     #     LSP server definitions
│   │   ├── notify.lua          #   nvim-notify + noice.nvim
│   │   ├── persistence.lua     #   persistence.nvim
│   │   ├── picker.lua          #   Snacks picker config
│   │   ├── statusline.lua      #   Heirline → statusline/init.lua
│   │   ├── telescope.lua       #   Telescope + fzf-native
│   │   ├── treesitter.lua      #   nvim-treesitter
│   │   ├── trouble.lua         #   trouble.nvim
│   │   └── whichkey.lua        #   which-key.nvim
│   │
│   ├── managers/               # Abstraction layer
│   │   ├── events.lua          #   Simple pub/sub event bus
│   │   ├── density.lua         #   UI density profiles
│   │   ├── focus.lua           #   Focus mode
│   │   ├── notifications.lua   #   Notification presets
│   │   ├── completion/         #   Completion adapter system
│   │   │   ├── init.lua        #     Manager + adapter registration
│   │   │   └── adapters/       #     Adapter implementations
│   │   │       └── blink_cmp.lua
│   │   ├── picker/             #   Picker adapter system
│   │   │   ├── init.lua        #     Manager + adapter registration
│   │   │   └── adapters/       #     Adapter implementations
│   │   │       ├── telescope.lua
│   │   │       └── snacks.lua
│   │   ├── format/             #   Formatting manager
│   │   │   └── init.lua
│   │   ├── lint/               #   Linting manager
│   │   │   └── init.lua
│   │   ├── lsp/                #   LSP manager
│   │   │   └── init.lua
│   │   └── git/                #   Git manager
│   │       └── init.lua
│   │
│   ├── statusline/             # Heirline statusline
│   │   └── init.lua            #   Components, layouts, density-aware
│   │
│   └── themes/                 # Theme system
│       ├── init.lua            #   Manager + discovery + switching
│       ├── catppuccin.lua      #   4 variants
│       ├── tokyonight.lua      #   4 variants
│       ├── kanagawa.lua        #   3 variants
│       ├── onedark.lua         #   1 variant
│       ├── everforest.lua      #   3 variants
│       ├── github.lua          #   5 variants
│       └── gruvbox-material.lua#   3 variants
│
└── docs/                       # Documentation
```

## File Naming Convention

| Pattern | Example | Description |
|---|---|---|
| `lua/core/*.lua` | `options.lua` | Bootstrap modules loaded at startup |
| `lua/config/*.lua` | `lazy.lua` | Single-file configuration modules |
| `lua/plugins/*.lua` | `treesitter.lua` | One file per plugin or concern |
| `lua/plugins/*/` | `lsp/` | Plugin group with multiple files |
| `lua/managers/*.lua` | `density.lua` | Top-level manager modules |
| `lua/managers/*/` | `picker/` | Manager with sub-modules |
| `lua/managers/*/adapters/` | `adapters/` | Adapter implementations |
| `lua/themes/*.lua` | `catppuccin.lua` | One file per color scheme collection |

---

**Previous:** [Overview](overview.md)
**Next:** [Startup Flow](startup-flow.md)
