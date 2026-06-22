# Migration History

## v1.0 (Current)

Initial release with the following architecture:

- **Lazy.nvim** as plugin manager.
- **Manager abstraction layer** with event bus.
- **Adapter pattern** for pickers (Telescope + Snacks) and completion.
- **Density profiles** (Full / Compact / Minimal).
- **Focus mode** (distraction-free editing).
- **Notification presets** (Rich / Minimal / Native).
- **Theme system** with auto-discovery, palette extraction, and plugin highlight preservation.
- **Statusline** using Heirline with density-aware layouts.
- **LSP** using Neovim 0.11's `vim.lsp.config`/`vim.lsp.enable`.
- **Completion** using blink.cmp (adapter-based).
- **Picker** using Telescope (default) with Snacks as alternative.

### Plugin choices at v1.0

| Category | Chosen | Alternative(s) Passed Over |
|---|---|---|
| Plugin manager | Lazy.nvim | packer.nvim (unmaintained), paq |
| Picker | Telescope | fzf-lua |
| Picker (alternative) | Snacks | none |
| Completion | blink.cmp | nvim-cmp |
| Statusline | Heirline | Lualine, Feline |
| Formatting | conform.nvim | none |
| Linting | nvim-lint | none |
| Git | gitsigns.nvim | fugitive |
| Debug | nvim-dap | none |
| Notifications | noice.nvim | none |
| Dashboard | Snacks (dashboard) | dashboard-nvim, alpha |
| Session | persistence.nvim | posession, resession |

---

**Previous:** [Plugin Comparisons](plugin-comparisons.md)
