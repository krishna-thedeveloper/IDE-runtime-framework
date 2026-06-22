# Coding Standards

## Naming Conventions

### Files and Directories

- **kebab-case** — `lua/managers/picker/init.lua`, `lua/plugins/bufferline.lua`.
- Directory names are singular: `manager/`, `plugin/`, `adapter/`.
- Init files are `init.lua` (Neovim convention).
- One concern per file.

### Modules

- Return a local `M` table:
  ```lua
  local M = {}
  -- ...
  return M
  ```
- Public functions are `M.snake_case`.
- Private functions are `M._snake_case` or `local function _snake_case`.
- Constants are `UPPER_CASE`:
  ```lua
  local PLUGIN_PREFIXES = { ... }
  ```

### Variables

- Local variables only. No global pollution.
- Descriptive names: `lazypath`, `theme_file`, `profile_order`.
- Use `vim.tbl_deep_extend` for merging config tables.
- Use `vim.tbl_map` / `vim.tbl_filter` over manual loops.

### Keymaps

- Always include `desc` attribute.
- Use string keys: `"<leader>ff"`.
- Buffer-local keymaps where appropriate (LSP, git).

## File Structure

### Plugin Spec Files

```lua
return {
  {
    "author/plugin",
    lazy = true,
    event = "VeryLazy",
    dependencies = { ... },
    opts = { ... },
    config = function(_, opts)
      require("plugin").setup(opts)
    end,
  },
}
```

### Manager Files

```lua
local M = {}
local state_dir = vim.fn.stdpath("state")
local state_file = state_dir .. "/name.txt"

-- State queries
function M.get_active_name() ... end
function M.get_current_index() ... end

-- Actions
function M.apply(name) ... end
function M.cycle() ... end
function M.select() ... end

-- Persistence
function M.save(name) ... end
function M.setup() ... end

-- Keymaps at module level
vim.keymap.set("n", "<leader>xx", M.action, { desc = "..." })

return M
```

### Adapter Files

```lua
local M = {
  label = "AdapterName",
}

function M.some_method() ... end

return M
```

## Code Style

- 2-space indentation (Lua convention).
- No trailing whitespace.
- Single quotes for strings unless interpolating.
- Function calls with parentheses: `vim.fn.stdpath("data")`.
- Table constructors with consistent alignment.

## Import Order

```lua
local M = {}

-- Standard library / Neovim API
local state_dir = vim.fn.stdpath("state")

-- Internal dependencies
local events = require("managers.events")

-- Module state
local active = nil
```

## Error Handling

- Use `pcall` for operations that might fail (plugin loading, highlight setting).
- Graceful degradation: check `package.loaded` before accessing plugin modules.
- No `assert` in production paths.

## Lua Version

- Targets LuaJIT (Lua 5.1 compatible).
- Use `vim.tbl_*` helpers instead of `table.*` where available.
- Use `vim.uv` instead of deprecated `vim.loop`.
- Use `vim.lsp.config` / `vim.lsp.enable` (Neovim 0.11+).

---

**Previous:** [Removing a Plugin](removing-a-plugin.md)
**Next:** [Debugging](debugging.md)
