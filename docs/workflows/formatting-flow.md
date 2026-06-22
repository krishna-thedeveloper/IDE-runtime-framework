# Formatting Workflow

## Configuration

Formatting is handled by `conform.nvim` configured via `lua/plugins/formatting.lua`, which delegates to `lua/managers/format/init.lua`.

## Trigger Events

Formatting triggers on:

1. **BufReadPre / BufNewFile** — conform.nvim loads its configuration.
2. **Manual trigger** — `<leader>cf` calls `managers.format.format()`.

## Format on Save

```lua
format_on_save = {
  lsp_fallback = true,
  timeout_ms = 500,
  stop_after_first = true,
}
```

When saving a buffer, conform.nvim formats using the configured formatter for the file type. If the formatter is unavailable, it falls back to LSP formatting.

## Per-FileType Formatters

```lua
formatters_by_ft = {
  lua = { "stylua" },
  javascript = { "prettierd", "prettier" },
  typescript = { "prettierd", "prettier" },
  javascriptreact = { "prettierd", "prettier" },
  typescriptreact = { "prettierd", "prettier" },
  json = { "prettierd", "prettier" },
  yaml = { "prettierd", "prettier" },
  markdown = { "prettierd", "prettier" },
  ["*"] = { "trim_whitespace" },
}
```

- Formatters are tried in order: `prettierd` first, then fallback to `prettier`.
- The `["*"]` catch-all applies `trim_whitespace` to all filetypes.

## Manual Formatting

```vim
<leader>cf
```

Calls:

```lua
function M.format(opts)
  opts = opts or {}
  require("conform").format(vim.tbl_deep_extend("force", {
    async = true,
    lsp_fallback = true,
    stop_after_first = true,
  }, opts))
end
```

---

**See also:** [LSP Flow](lsp-flow.md), [Diagnostics Flow](diagnostics-flow.md)
