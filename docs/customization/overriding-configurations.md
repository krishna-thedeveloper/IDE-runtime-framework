# Overriding Configurations

## Current Approach

Without a dedicated user config module, the recommended approach is to modify the source files directly. Each file is designed to be self-contained, making modifications straightforward.

### Changing Theme Defaults

Edit `lua/themes/<name>.lua`:

```lua
-- Change catppuccin default from mocha to latte
local variants = {
  -- Swap order or modify
  { name = "catppuccin", flavour = "mocha", is_light = false },
}
```

### Changing Keymaps

Edit the relevant file:

- **Global keymaps**: `lua/core/keymaps.lua`.
- **Plugin keymaps**: `lua/plugins/<name>.lua` (in `keys` field).
- **Manager keymaps**: `lua/managers/<name>.lua` (at module level).

### Changing LSP Server Config

Edit `lua/plugins/lsp/servers.lua` to add/modify server settings.

### Changing Formatters

Edit `lua/plugins/formatting.lua` to modify `formatters_by_ft`.

## Best Practices for Overrides

1. **Make one change at a time** to isolate effects.
2. **Prefer adding over removing** — append to lists rather than replacing them.
3. **Keep changes minimal** — modify only what you need.
4. **Document your changes** — add comments if you deviate from defaults.

---

**Previous:** [User Options](user-options.md)
**Next:** [Creating Modules](creating-modules.md)
