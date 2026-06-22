# First Launch

## What Happens

When you start Neovim for the first time, this initialization chain executes:

```
init.lua
  → core/options.lua       (Neovim options + leaders)
  → core/keymaps.lua       (core keymaps, loads managers)
  → core/autocmds.lua      (global autocommands)
  → config/lazy.lua        (Lazy.nvim bootstrap + plugin loading)
```

See [Startup Flow](../architecture/startup-flow.md) for the full sequence.

## After Launch

1. **Lazy dashboard** appears (if no file is opened) showing plugin status.
2. Press `q` to close it, or wait for plugin installation to finish.
3. Open a file: `:e src/main.ts`
4. Find files: `<leader>ff`
5. Live grep: `<leader>fg`

## Key First Actions

| Action | Key | Description |
|---|---|---|
| Find files | `<leader>ff` | Opens picker (Telescope or Snacks) |
| Live grep | `<leader>fg` | Search file contents |
| Save | `<leader>w` | Write buffer |
| Close | `<leader>q` | Close window |
| Theme cycle | `<leader>tc` | Cycle through installed themes |
| Density cycle | `<leader>uc` | Full → Compact → Minimal |
| Focus mode | `<leader>z` | Toggle focus mode |
| Which-key | `<leader>` | Wait 500ms to see available keymaps |
| Lazy | `:Lazy` | Open Lazy.nvim dashboard |
| Mason | `:Mason` | Install LSP servers, formatters, linters |

## Troubleshooting First Launch

| Symptom | Likely Cause |
|---|---|
| "Failed to clone lazy.nvim" | No internet or `git` not installed |
| Missing icons | No Nerd Font installed or configured in terminal |
| LSP not working | Server not installed via Mason |
| Formatting not working | Formatter not on `$PATH` |
| Slow startup | Treesitter parsers being built (first launch only) |

---

**Previous:** [Requirements](requirements.md)
**Next:** [Updating](updating.md)
