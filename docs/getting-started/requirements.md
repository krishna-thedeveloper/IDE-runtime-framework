# Requirements

## Neovim Version

Minimum: **Neovim 0.11** (nightly builds or stable 0.11+).

APIs used that require 0.11+:

- `vim.lsp.config()` / `vim.lsp.enable()` — used in `managers/lsp/init.lua` for declarative LSP setup.
- `vim.lsp.buf.hover({ border, title, title_pos })` — enhanced hover UI with styled documentation window.
- `vim.uv` (preferred over deprecated `vim.loop`).

Check your version:

```bash
nvim --version
```

## System Dependencies

| Dependency | Required | Purpose |
|---|---|---|
| `git` | Yes | Plugin management, gitsigns |
| `make` | For some plugins | Telescope FZF native build, LuaSnip jsregexp |
| `npm` / `node` | Recommended | TS/JS LSP server (`ts_ls`), Prettier |
| `stylua` | Recommended | Lua formatting |
| `lua-language-server` | Recommended | Lua LSP (auto-installed by mason) |
| `rg` (ripgrep) | Recommended | Telescope live grep, Snacks grep |
| `fd` | Recommended | Telescope/Snacks file finding |
| `lazygit` | Optional | Git UI |

## Neovim Capabilities

The configuration assumes:

- `termguicolors` enabled (truecolor terminal).
- A clipboard tool (`xclip`, `wl-clipboard`, `pbcopy`, etc.) for system clipboard integration.

## Font

A [Nerd Font](https://www.nerdfonts.com/) is strongly recommended. Icons are used extensively in:

- **Statusline** (`lua/statusline/init.lua`) — mode indicators, git symbols, diagnostics icons.
- **Bufferline** (`lua/plugins/bufferline.lua`) — close icons, modified indicators.
- **Which-key** (`lua/plugins/whichkey.lua`) — group icons.
- **Notifications** (`lua/plugins/notify.lua`) — severity icons.
- **Dashboard** (`lua/plugins/dashboard.lua`) — section icons.
- **Picker** (`lua/plugins/picker.lua`) — prompt prefix.

Without a Nerd Font, replace `icons` entries or install one.

Recommended: [JetBrainsMono Nerd Font](https://github.com/ryanoasis/nerd-fonts/releases)

## Optional Tools

| Tool | Integrates via | Purpose |
|---|---|---|
| `lazygit` | `:LazyGit` (if configured) | Git TUI |
| `chrome` / `brave` | `vim.ui.open()` | URL opening in noice markdown |

---

**Previous:** [Installation](installation.md)
**Next:** [First Launch](first-launch.md)
