# LSP Workflow

## Initialization

LSP is set up through a chain of plugin configs:

```mermaid
sequenceDiagram
    participant L as Lazy.nvim
    participant M as lua/plugins/lsp/mason.lua
    participant ML as mason-lspconfig
    participant LC as lua/plugins/lsp/lspconfig.lua
    participant LS as lua/managers/lsp/init.lua
    participant S as lua/plugins/lsp/servers.lua
    participant C as lua/managers/completion/init.lua

    Note over L: On first BufReadPre
    L->>M: Load mason.lua spec
    M->>M: mason.setup({ ui = { border = "rounded" } })
    M->>ML: mason-lspconfig.setup({ ensure_installed = [...] })

    Note over L: nvim-lspconfig depends on mason-lspconfig
    L->>LC: Load nvim-lspconfig
    LC->>LS: require("managers.lsp").setup()

    LS->>LS: Register LspAttach autocmd
    Note over LS: LspAttach configures:<br/>gd, gr, gi, K,<br/>renaming, code actions,<br/>diagnostics navigation

    LS->>LS: vim.diagnostic.config(...)

    LS->>C: require("managers.completion").get_capabilities()
    C->>C: Get active adapter capabilities
    C-->>LS: LSP capabilities table

    LS->>S: Load servers.lua
    LS->>LS: vim.lsp.config("*", { capabilities })
    loop for each server
        LS->>LS: vim.lsp.config(server, config)
        LS->>LS: vim.lsp.enable(server)
    end
```

## LSP Attach (Per-Buffer)

When an LSP server attaches to a buffer:

1. **Keymaps are set** (buffer-local):
   - `gd` → definition
   - `gr` → references
   - `gi` → implementation
   - `K` → hover (with styled border)
   - `<leader>rn` → rename
   - `<leader>ca` → code action
   - `[d` / `]d` → diagnostic navigation
   - `<leader>e` → diagnostic float

2. **Completion capabilities** are merged — the completion engine (blink.cmp) receives the server's capabilities.

3. **Diagnostics** begin flowing:
   - Virtual text (prefix + source)
   - Signs in the gutter
   - Underline highlights
   - Severity-sorted

## LSP and Completion Integration

The capability flow:

```
blink.cmp.get_lsp_capabilities()
  → managers.completion.get_capabilities()
    → managers.lsp.setup()
      → vim.lsp.config("*", { capabilities })
```

When the completion engine is switched via `managers.completion.cycle()`, capabilities are re-applied:

```lua
function M.use(name)
  M._active = name
  M._save(name)
  pcall(vim.lsp.config, "*", { capabilities = M.get_capabilities() })
  vim.notify("Completion: " .. name .. " — restart session for full engine swap")
end
```

**Note:** Full engine swap requires a session restart because LSP clients are already initialized with the previous capabilities.

## Troubleshooting LSP

```vim
:LspInfo           " Which servers are running, which buffers attached
:LspLog            " LSP client log
:Mason             " Check server installation status
```

```lua
:lua print(vim.inspect(vim.lsp.get_clients({ bufnr = 0 })))
:lua print(vim.inspect(require("managers.completion").get_capabilities()))
```

---

**See also:** [LSP Plugins](../plugins/lsp.md), [Completion Flow](completion-flow.md), [Diagnostics Flow](diagnostics-flow.md)
