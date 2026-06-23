# Nvim IDE

A modular, performant Neovim configuration built with Lazy.nvim. Designed for long-term maintainability, runtime extensibility, and a polished IDE experience.

## Philosophy

- **Modular over monolithic** — every concern has its own file, directory, and abstraction level.
- **Swappable at runtime** — pickers, completion engines, notification presets, and density levels can be switched live without restart.
- **Minimal startup overhead** — lazy-load everything except what's needed for first keystroke.
- **Framework-like architecture** — managers, adapters, events, and profiles form a small but powerful framework that plugins sit on top of.

## Features

| Area | Implementation |
|---|---|
| Plugin Manager | Lazy.nvim / pckr.nvim / mini.deps / vim.pack (swappable via config) |
| Picker | Telescope + Snacks (swappable) |
| Completion | blink.cmp (adapter-based) |
| LSP | nvim-lspconfig + mason.nvim |
| Formatting | conform.nvim |
| Linting | nvim-lint |
| Statusline | Heirline (3 density presets) |
| Bufferline | bufferline.nvim |
| Notifications | noice.nvim + nvim-notify (3 presets) |
| Dashboard | Snacks dashboard |
| Debugging | nvim-dap + nvim-dap-ui |
| Git | gitsigns.nvim |
| Treesitter | nvim-treesitter |
| Indent guides | indent-blankline.nvim |
| Session | persistence.nvim |
| UI helpers | which-key.nvim, trouble.nvim |
| Themes | 7 color schemes, 22+ variants |


## Installation

```bash
git clone https://github.com/<your-org>/nvim ~/.config/nvim
nvim --headless "+lua require('config.plugin_manager')" +qa
```

### Requirements

- Neovim >= 0.11
- git
- A [Nerd Font](https://www.nerdfonts.com/) (optional, for icons)
- Language-specific LSP servers (auto-installed via mason.nvim)

## Quick Start

1. Install the configuration (see above).
2. Open `nvim` — The plugin manager downloads and sets up all plugins automatically.
3. Press `<Space>` to see which-key popup.
4. Press `<leader>ff` to find files.
5. Press `<leader>tc` to cycle themes.

## Documentation

| Section | Contents |
|---|---|
| [Getting Started](docs/getting-started/installation.md) | Installation, requirements, first launch, updating |
| [Architecture](docs/architecture/overview.md) | Repository structure, startup flow, lazy-loading, dependency graph, abstractions |
| [Plugins](docs/plugins/plugin-system.md) | Every plugin: purpose, alternatives, configuration, extension points |
| [Themes](docs/themes/theme-system.md) | Theme system, switching, creating new themes |
| [Keymaps](docs/keymaps/keymaps-overview.md) | Complete key reference, leader mappings, which-key |
| [Development](docs/development/adding-a-plugin.md) | Adding/removing plugins, coding standards, naming conventions, debugging |
| [Workflows](docs/workflows/startup-sequence.md) | Startup, search, LSP, completion, formatting, diagnostics flows |
| [Performance](docs/performance/startup-optimization.md) | Startup optimization, lazy-loading strategy, benchmarks |
| [Customization](docs/customization/user-options.md) | User options, overriding configs, creating modules, extending features |
| [Reference](docs/reference/commands.md) | Commands, autocommands, options, globals, environment variables |
| [Troubleshooting](docs/troubleshooting/common-issues.md) | Common issues, FAQ |
| [Decisions](docs/decisions/why-this-architecture.md) | Architecture decisions, plugin comparisons, migration history |

## Key Highlights

- **Runtime-switchable pickers** — `:lua require("managers.picker").cycle()` toggles between Telescope and Snacks picker without restart.
- **Runtime-switchable completion** — `:lua require("managers.completion").cycle()` swaps completion engines.
- **Density presets** — Full IDE, Compact, and Minimal profiles adjust every UI element simultaneously: statusline layout, bufferline visibility, indent guides, and notification richness.
- **Theme variants** — 22+ theme variants across 7 color schemes, all switchable at runtime with full plugin highlight restoration.
- **Event bus** — Internal pub/sub system (`managers.events`) coordinates cross-manager communication without direct coupling.
- **Adapter pattern** — Pickers, completion engines, and plugin managers are abstracted behind a common interface; adding a new backend requires only an adapter file. Switch plugin managers by changing one line in `lua/config/plugin_manager.lua`.
- **Multi-adapter plugin system** — Choose from 4 backends: Lazy.nvim (default), pckr.nvim, mini.deps, or vim.pack. Universal spec fields (events, keys, commands, filetypes, dependencies, opts, config, condition, priority) work across all adapters.

See [Coding Standards](docs/development/coding-standards.md) for conventions.

## License

MIT
