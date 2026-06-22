# Startup Optimization

## Strategy

This configuration prioritizes startup speed through aggressive lazy-loading. The guiding principle: **if it's not needed for the first keystroke, don't load it.**

## What Loads at Startup

| Module | Reason | Cost |
|---|---|---|
| `core/options.lua` | Neovim options must be set before UI renders | ~1ms |
| `core/keymaps.lua` | Keymaps must be registered | ~5ms (manager discovery) |
| `core/autocmds.lua` | Global autocmds | ~1ms |
| `lazy.nvim` bootstrap | Plugin manager must init | ~10-20ms |
| `nvim-treesitter` (spec) | Must be ready for syntax highlighting | ~5ms (spec) |
| Active colorscheme | Must render before UI | ~15-30ms |
| **Total** | | **~30-60ms** |

## What Defers to VeryLazy

All deferred plugins load after startup but before user interaction with specific UI elements:

| Plugin | Typical Load Time | Priority |
|---|---|---|
| `heirline.nvim` | ~8ms | Statusline |
| `bufferline.nvim` | ~5ms | Buffer tabs |
| `indent-blankline.nvim` | ~3ms | Indent guides |
| `which-key.nvim` | ~4ms | Keymap help |
| `noice.nvim` | ~10ms | Notification UI |
| `nvim-notify` | ~3ms | Notification backend |

These load within ~100ms of startup, asynchronously.

## Lazy-Loading Triggers

| Trigger | Plugins |
|---|---|
| `BufReadPre` / `BufNewFile` | conform.nvim, nvim-lint |
| `BufReadPre` | persistence.nvim |
| Keymaps | nvim-dap + dap-ui |
| Commands | trouble.nvim, oil.nvim |
| Adapter dispatch | telescope.nvim, snacks.nvim (picker) |
| InsertEnter | blink.cmp, mini.pairs |

## Cleanup After Pickers

Telescope and Snacks picker adapters implement post-action cleanup that unloads the plugin modules from `package.loaded`. This ensures picker plugins don't consume memory when not in use:

```lua
local function cleanup()
  for k in pairs(package.loaded) do
    if type(k) == "string" and (k:find("^telescope") or k == "fzf_lib") then
      package.loaded[k] = nil
    end
  end
  require("lazy.core.config").plugins["telescope.nvim"]._.loaded = nil
end
```

## Theme Lazy Optimization

Only the active theme's plugin is loaded eagerly. All other color scheme plugins are lazy:

```lua
{
  "catppuccin/nvim",
  lazy = active_group ~= "catppuccin",   -- lazy if not active
  priority = 1000,
}
```

This saves ~50-100ms on startup compared to loading all 7 color scheme plugins.

## Manager State Restoration

Manager state files are read synchronously at `require` time, but visual state changes are deferred:

- **Density**: Applied via `vim.schedule` if the saved profile is not the default (`full`).
- **Notifications**: Applied via `vim.schedule` if the saved preset is not the default (`rich`).

This prevents visual flickering during startup.

## Benchmark Methodology

```bash
# Measure cold startup
nvim --headless +qa 2>&1

# Measure with Lazy profile
nvim --headless "+Lazy! profile" +qa
```

Expected startup times (cold, no cache):

| Scenario | Target |
|---|---|
| Cold startup | < 100ms |
| Warm startup (cached parsers) | < 60ms |
| With VeryLazy deferred | < 200ms total including deferred |

---

**See also:** [Lazy Loading Strategy](lazy-loading-strategy.md), [Profiling](../development/profiling.md)
