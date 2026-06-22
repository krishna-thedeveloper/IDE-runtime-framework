# Leader Mappings

## The Leader Key

The leader key is `<Space>` (set in `lua/core/options.lua:22`):

```lua
vim.g.mapleader = " "
vim.g.maplocalleader = "\\"
```

## Mapping Convention

- Single keystrokes after leader: `leader + key` (e.g., `<leader>w` for save, `<leader>q` for quit).
- Two-character sequences: `leader + group + action` (e.g., `<leader>ff` = Find Files, `<leader>gs` = Git Stage).
- Group prefixes are registered with which-key so pressing `<leader>` and waiting shows the popup.

## Which-Key Group Registrations

Defined in `lua/plugins/whichkey.lua:14`:

```lua
wk.add({
  { "<leader>f", group = "Find" },
  { "<leader>g", group = "Git" },
  { "<leader>c", group = "Code" },
  { "<leader>u", group = "UI" },
  { "<leader>n", group = "Notifications" },
  { "<leader>d", group = "Debug" },
  { "<leader>x", group = "Trouble" },
  { "<leader>S", group = "Session" },
  { "<leader>s", group = "Select" },
})
```

## Adding a New Leader Mapping

Add to the appropriate location following this decision tree:

```
Is it a core editor action?           → lua/core/keymaps.lua
Is it for a manager (cycle/select)?   → lua/managers/<name>.lua
Is it for a specific plugin?          → lua/plugins/<name>.lua
Is it set up during LspAttach?        → lua/managers/lsp/init.lua
Is it set up during git attach?       → lua/managers/git/init.lua
```

Example — adding a new find mapping:

```lua
-- In lua/core/keymaps.lua
vim.keymap.set("n", "<leader>fz", picker.some_custom_search, { desc = "Custom search" })
```

Then register the group if needed:

```lua
-- In lua/plugins/whichkey.lua
{ "<leader>f", group = "Find" },  -- already exists
```

---

**Previous:** [Keymaps Overview](keymaps-overview.md)
**Next:** [Which-Key](which-key.md)
