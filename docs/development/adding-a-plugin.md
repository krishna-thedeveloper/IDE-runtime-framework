# Adding a Plugin

## Step-by-Step

### 1. Create the Spec File

Create a new file in `lua/plugins/`:

```lua
-- lua/plugins/my-plugin.lua
return {
  {
    "author/my-plugin.nvim",
    lazy = true,  -- unless it must load at startup
    event = "VeryLazy",
    opts = {
      -- plugin options
    },
    config = function(_, opts)
      require("my-plugin").setup(opts)
    end,
  },
}
```

### 2. Choose Loading Strategy

| If the plugin... | Use trigger |
|---|---|
| Provides syntax/indent | `lazy = false` or `event = "BufReadPre"` |
| Is UI/visual only | `event = "VeryLazy"` |
| Has specific commands | `cmd = "MyCommand"` |
| Has specific keymaps | `keys = { { "n", "<leader>x", ... } }` |
| Is for a filetype | `ft = "markdown"` |
| Is used by another plugin | Add to that plugin's `dependencies` |

### 3. Set Dependencies

```lua
dependencies = {
  "other/plugin",
  "another/plugin",
}
```

### 4. Add Keymaps

If the plugin has leader keymaps, register the group in `lua/plugins/whichkey.lua`:

```lua
wk.add({
  { "<leader>m", group = "My Plugin" },
})
```

Define keymaps either in the plugin spec's `keys` field or in the `config` function.

### 5. Configure (if needed)

If the plugin integrates with an existing manager abstraction:

- **Formatting** → delegate to `managers.format`
- **Linting** → delegate to `managers.lint`
- **LSP** → add to `lua/plugins/lsp/servers.lua`
- **Picker** → implement an adapter in `managers/picker/adapters/`
- **Completion** → implement an adapter in `managers/completion/adapters/`

### 6. Install

```vim
:Lazy sync
```

## Examples

### Adding a Plugin with Command Trigger

```lua
-- lua/plugins/hexokinase.lua
return {
  {
    "RRethy/vim-hexokinase",
    cmd = "HexokinaseToggle",
    build = "make",
    config = function()
      vim.g.Hexokinase_optInPatterns = "full_hex,triple_hex,rgb,rgba,hsl,hsla"
    end,
  },
}
```

### Adding a Plugin with Keymap Trigger

```lua
-- lua/plugins/toggleterm.lua
return {
  {
    "akinsho/toggleterm.nvim",
    keys = {
      { "<leader>tt", "<cmd>ToggleTerm<CR>", desc = "Toggle terminal" },
    },
    opts = {
      size = 20,
      open_mapping = [[<c-\>]],
      direction = "horizontal",
    },
  },
}
```

---

**Next:** [Removing a Plugin](removing-a-plugin.md)
**See also:** [Plugin System](../plugins/plugin-system.md), [Coding Standards](coding-standards.md)
