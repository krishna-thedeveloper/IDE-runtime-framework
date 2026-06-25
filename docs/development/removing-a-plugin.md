# Removing a Plugin

## Steps

### 1. Delete the spec file

```bash
rm lua/plugins/<plugin-name>.lua
```

### 2. Remove references

Check for cross-references to the plugin:

```bash
rg "plugin-name" lua/
```

Common places to check:

- `lua/plugins/whichkey.lua` — leader group registration.
- `lua/managers/*.lua` — adapter implementations.
- Other plugin spec `dependencies` fields.
- `lua/plugins/colorschemes.lua` — if removing a theme.

### 3. Remove keymaps

If the plugin had leader keymaps, remove them from wherever they were defined.

### 4. Consider replacements

If the plugin filled a role covered by the adapter systems:

- **Picker**: Remove from `managers/picker/init.lua`'s discover directory, delete the adapter file.
- **Completion**: Same pattern.
- **Formatting/Linting**: Remove the delegation from the plugin spec — but since conform/nvim-lint handle multiple formatters/linters, you only need to remove the specific formatter from the config.

### 5. Sync

```vim
:Lazy clean   # removes unneeded plugins
:Lazy sync
```

## Example: Removing a Theme

1. Delete the theme file: `rm lua/themes/oldtheme.lua`.
2. Remove from `lua/plugins/colorschemes.lua`.
3. Remove the variant entry from the theme file (e.g., `lua/themes/catppuccin.lua`).

---

**Previous:** [Adding a Plugin](adding-a-plugin.md)
**Next:** [Coding Standards](coding-standards.md)
