# Installation

## Prerequisites

Before installing, ensure you have the following:

- **Neovim >= 0.11** — required for `vim.lsp.config`, `vim.lsp.enable`, and other modern APIs used throughout the configuration.
- **git** — used by Lazy.nvim to clone plugins and by this configuration to manage itself.
- **A Nerd Font** (optional but recommended) — many UI components use icons (statusline, bufferline, which-key). Without a Nerd Font, glyphs will render as missing characters.
- **Language runtimes** — LSP servers are auto-installed via mason.nvim, but some require platform tooling (e.g., `npm` for `ts_ls`, `stylua` for Lua formatting).

## Clone

```bash
git clone https://github.com/<your-org>/nvim ~/.config/nvim
```

If you already have an existing Neovim configuration, back it up first:

```bash
mv ~/.config/nvim ~/.config/nvim.bak
mv ~/.local/share/nvim ~/.local/share/nvim.bak
mv ~/.local/state/nvim ~/.local/state/nvim.bak
```

## Bootstrap

Launch Neovim. Lazy.nvim will auto-install on first startup:

```bash
nvim
```

Lazy.nvim bootstraps itself by cloning into `stdpath("data")/lazy/lazy.nvim`, then reads all plugin specs from `lua/plugins/`. All plugins are downloaded and set up automatically.

To explicitly sync:

```bash
nvim --headless "+Lazy! sync" +qa
```

## Verify

Run the Lazy health check:

```bash
nvim --headless "+Lazy! health" +qa
```

Or open the Lazy dashboard from within Neovim:

```
:Lazy
```

## Post-Install

1. **Treesitter parsers** are installed asynchronously on first `UIEnter`. You can also run `:TSInstall all` manually.
2. **LSP servers** listed in `lua/plugins/lsp/servers.lua` are auto-installed via mason-lspconfig on first LSP attach.
3. **Mason tools** (formatters, linters) need to be installed manually via `:Mason` or will be auto-detected if already on `$PATH`.

---

**Next:** [Requirements](requirements.md)
**Up:** [Getting Started](../getting-started/installation.md)
