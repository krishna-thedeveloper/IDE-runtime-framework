# Naming Conventions

## Directory Naming

| Pattern | Example | When to use |
|---|---|---|
| `lua/core/` | `options.lua` | Bootstrap modules loaded on every startup |
| `lua/config/` | `lazy.lua` | Single-purpose configuration files |
| `lua/plugins/` | `treesitter.lua` | Lazy.nvim plugin spec files |
| `lua/plugins/<group>/` | `lsp/init.lua` | Related plugin specs |
| `lua/managers/` | `density.lua` | Top-level abstraction managers |
| `lua/managers/<name>/` | `picker/init.lua` | Managers with submodules |
| `lua/managers/<name>/adapters/` | `telescope.lua` | Adapter implementations |
| `lua/themes/` | `catppuccin.lua` | Theme definitions |
| `lua/statusline/` | `init.lua` | Standalone UI module |

## File Naming

- `init.lua` — entry point for a module directory.
- `lazy.lua` — Lazy.nvim configuration (special case).
- All other files: **kebab-case** — `bufferline.lua`, `whichkey.lua`, `blink_cmp.lua`.

## Lua Module Naming

Modules map directly to file paths:

| File | `require(...)` |
|---|---|
| `lua/core/options.lua` | `"core.options"` |
| `lua/config/plugin_manager.lua` | `"config.plugin_manager"` |
| `lua/plugins/lsp/init.lua` | `"plugins.lsp"` |
| `lua/plugins/lsp/servers.lua` | `"plugins.lsp.servers"` |
| `lua/managers/picker/init.lua` | `"managers.picker"` |
| `lua/managers/picker/adapters/telescope.lua` | `"managers.picker.adapters.telescope"` |
| `lua/statusline/init.lua` | `"statusline"` |

## Function Naming

| Convention | Example | Use |
|---|---|---|
| `snake_case` | `get_active_name()` | Public API functions |
| `_snake_case` | `_apply_visual()` | Private/internal functions |
| `UPPER_CASE` | `PLUGIN_PREFIXES` | Constants |

## Keymap Naming

| Convention | Example | Use |
|---|---|---|
| `<leader>XX` | `<leader>ff` | Two-letter leader sequence: group + action |
| `<leader>Xx` | `<leader>Ss` | Capital = specific action, lowercase = common |
| Single key | `gd`, `gr`, `K` | LSP and other non-leader maps |

## Manager API Convention

Every manager that supports runtime switching follows this API:

```
M.get_active_name()  → string        -- current state name
M.cycle()            → nil           -- rotate to next option
M.select()           → nil           -- show vim.ui.select picker
M.apply(name)        → nil           -- set specific option by name
M.setup()            → nil           -- called by plugin config on load
M.save(name)         → nil           -- persist to state file
```

---

**Previous:** [Coding Standards](coding-standards.md)
**Next:** [Debugging](debugging.md)
