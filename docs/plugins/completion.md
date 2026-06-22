# Completion Plugin

## blink.cmp

**File:** `lua/plugins/completion.lua`

- **Purpose:** Code completion engine with LSP, snippets, path, and buffer completion sources.
- **Why blink.cmp:** It is the next-generation completion engine for Neovim, designed to replace nvim-cmp. It is faster, has a cleaner architecture, and supports modern Neovim APIs natively.
- **Alternatives considered:** nvim-cmp (legacy, slower, more complex configuration).
- **Adapter:** blink.cmp has an adapter registered at `lua/managers/completion/adapters/blink_cmp.lua`.

### Configuration

```lua
opts = {
  keymap = {
    preset = "default",
    ["<CR>"] = { "accept", "fallback" },
  },
  appearance = { nerd_font_variant = "mono" },
  snippets = { preset = "luasnip" },
  sources = {
    default = { "lsp", "path", "snippets", "buffer" },
  },
  completion = {
    documentation = { auto_show = true, auto_show_delay_ms = 500 },
    ghost_text = { enabled = true },
    menu = {
      draw = {
        columns = {
          { "label", "label_description", gap = 1 },
          { "kind_icon", "kind" },
        },
      },
    },
  },
}
```

### Key Features

- **Ghost text**: Inline completion preview (enabled).
- **Documentation popup**: Auto-shows with 500ms delay.
- **Custom menu layout**: Two-column: label + description, then kind icon + kind name.
- **LSP capabilities**: Delegated to `managers.completion` for integration with the LSP manager.

## LuaSnip

**File:** `lua/plugins/completion.lua`

- **Purpose:** Snippet engine for Neovim.
- **Why LuaSnip:** Most feature-rich snippet engine, supports VSCode-style snippets, Lua-based snippets, and advanced transformations.

### Configuration

```lua
config = function()
  require("luasnip.loaders.from_vscode").lazy_load()
  require("luasnip.loaders.from_vscode").lazy_load({
    paths = { vim.fn.stdpath("config") .. "/snippets" },
  })
end
```

- **Lazy loading**: Snippets from `friendly-snippets` (dependency) and custom snippets from `~/.config/nvim/snippets/` are loaded on demand.

## Friendly Snippets

**File:** dependency of blink.cmp in `lua/plugins/completion.lua`

- **Purpose:** Community-maintained collection of VSCode-style snippets for many languages.
- **Why:** Provides comprehensive snippet coverage without manual authoring.

## Custom Snippets

Place custom VSCode-style snippet files in:

```
~/.config/nvim/snippets/
```

These are loaded automatically by the LuaSnip config.

---

**Previous:** [LSP](lsp.md)
**Next:** [Treesitter](treesitter.md)
**See also:** [Completion Flow](../workflows/completion-flow.md), [Completion Manager](../architecture/abstractions.md#3-completion-adapter-system-managerscompletion)
