# Debug Plugin

## nvim-dap + nvim-dap-ui

**File:** `lua/plugins/debug.lua`

- **Plugin:** `mfussenegger/nvim-dap` + `rcarriga/nvim-dap-ui`
- **Purpose:** Debug Adapter Protocol client for Neovim. Provides breakpoints, stepping, variable inspection, and REPL.
- **Why nvim-dap:** The de facto standard DAP client for Neovim. Lightweight, extensible, works with any DAP-compliant debug adapter.
- **Alternatives:** None serious (nvim-dap is the standard).
- **Lazy loading:** Via keymaps (`keys`). Loaded on first debug keypress.
- **Dependencies:** `nvim-nio` (async IO for dap-ui).

## Configuration

```lua
dap.listeners.after.event_initialized["dapui_config"] = function()
  dapui.open()
end
dap.listeners.before.event_terminated["dapui_config"] = function()
  dapui.close()
end
dap.listeners.before.event_exited["dapui_config"] = function()
  dapui.close()
end
```

DAP UI auto-opens when a debug session starts and auto-closes when it ends.

## Keymaps

| Key | Action |
|---|---|
| `<leader>db` | Toggle breakpoint |
| `<leader>dB` | Set conditional breakpoint (prompts for condition) |
| `<leader>dc` | Continue |
| `<leader>dC` | Run to cursor |
| `<leader>do` | Step over |
| `<leader>di` | Step into |
| `<leader>dO` | Step out |
| `<leader>dr` | Toggle REPL |
| `<leader>du` | Toggle DAP UI |
| `<leader>dh` | DAP hover |

## Adding a Debug Adapter

Debug adapters are not configured in this repository by default. To add one (e.g., for Python's `debugpy`):

```lua
-- In lua/plugins/debug.lua or a new file
require("dap").adapters.python = {
  type = "executable",
  command = "python",
  args = { "-m", "debugpy.adapter" },
}
require("dap").configurations.python = {
  {
    type = "python",
    request = "launch",
    name = "Launch file",
    program = "${file}",
  },
}
```

---

**Up:** [Plugin System](plugin-system.md)
