# Treesitter

## nvim-treesitter

**File:** `lua/plugins/treesitter.lua`

- **Purpose:** Provides syntax highlighting, indentation, and folding powered by Tree-sitter.
- **Why it exists:** Tree-sitter gives precise, robust syntax highlighting and code-aware indentation without the fragility of regex-based approaches.
- **Lazy loading:** `lazy = false` — loaded at startup because highlighting is needed for the first file open.

### Configuration

```lua
opts = {
  ensure_installed = {
    "lua", "javascript", "typescript", "tsx",
    "proto", "json", "yaml", "toml",
    "bash", "markdown", "markdown_inline",
  },
  highlight = { enable = true },
  indent = { enable = true },
}
```

### Features

- **Highlight**: Enabled globally for all supported languages.
- **Indent**: Enabled globally, providing language-aware indentation.
- **Folding**: Configured in `lua/core/options.lua`:
  ```lua
  vim.opt.foldmethod = "expr"
  vim.opt.foldexpr = "v:lua.vim.treesitter.foldexpr()"
  vim.opt.foldlevel = 99  -- all folds open by default
  ```

### Auto-Install on UIEnter

On first launch, missing parsers are auto-installed:

```lua
vim.api.nvim_create_autocmd("UIEnter", {
  once = true,
  callback = function()
    local installed = TS.get_installed()
    local to_install = {}
    for _, lang in ipairs(opts.ensure_installed) do
      if not vim.tbl_contains(installed, lang) then
        table.insert(to_install, lang)
      end
    end
    if #to_install > 0 then
      pcall(TS.install, to_install, { summary = true })
    end
  end,
})
```

This defers parser installation to after startup, avoiding blocking the initial render.

### Per-FileType Setup

```lua
vim.api.nvim_create_autocmd("FileType", {
  group = vim.api.nvim_create_augroup("treesitter_features", { clear = true }),
  callback = function(ev)
    local lang = vim.treesitter.language.get_lang(ev.match)
    if not lang then return end
    if opts.highlight.enable ~= false then
      pcall(vim.treesitter.start, ev.buf)
    end
    if opts.indent.enable ~= false then
      vim.bo[ev.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
    end
  end,
})
```

### Adding a Language

Add the language name to `ensure_installed` in `lua/plugins/treesitter.lua`:

```lua
ensure_installed = {
  -- ... existing languages
  "rust",
  "python",
  "go",
}
```

---

**Previous:** [Completion](completion.md)
**Up:** [Plugins](plugin-system.md)
