# LSP Plugins

## Stack

```
mason.nvim
  └── mason-lspconfig.nvim   (auto-installs servers)
        └── nvim-lspconfig   (configures servers)
              └── managers.lsp.setup()
                    ├── plugins.lsp.servers  (server definitions)
                    └── managers.completion.get_capabilities()
```

## mason.nvim

**File:** `lua/plugins/lsp/mason.lua`

- **Purpose:** Portable package manager for LSP servers, formatters, and linters.
- **Why it exists:** Eliminates manual installation of language servers. Users get a consistent UI (`:Mason`) for managing tools.
- **Configuration:** Rounded borders, no automatic installation (controlled by `mason-lspconfig`).

## mason-lspconfig.nvim

**File:** `lua/plugins/lsp/mason.lua`

- **Purpose:** Bridges mason.nvim and nvim-lspconfig. Ensures specified servers are installed.
- **Configuration:**
  ```lua
  ensure_installed = { "ts_ls", "lua_ls", "jsonls", "yamlls" }
  automatic_installation = false  -- manual control
  ```

## nvim-lspconfig

**File:** `lua/plugins/lsp/lspconfig.lua`

- **Purpose:** Provides declarative LSP server configuration via `vim.lsp.config` (Neovim 0.11+ API).
- **Configuration delegation:** Calls `managers.lsp.setup()` which:
  1. Registers `LspAttach` autocmd with keymaps (gd, gr, gi, K, renaming, code actions, diagnostics navigation).
  2. Configures `vim.diagnostic.config` for virtual text, signs, underlines, and float windows.
  3. Reads capabilities from `managers.completion.get_capabilities()`.
  4. Iterates over `plugins.lsp.servers` and calls `vim.lsp.config(server, config)` + `vim.lsp.enable(server)`.

## Server Definitions

**File:** `lua/plugins/lsp/servers.lua`

Defines per-server configuration:

```lua
return {
  ts_ls = {
    settings = {
      typescript = {
        preferences = { importModuleSpecifier = "relative" },
      },
    },
  },
  lua_ls = {
    settings = {
      Lua = {
        diagnostics = { globals = { "vim" } },
        workspace = { checkThirdParty = false },
      },
    },
  },
  jsonls = {},
  yamlls = {},
}
```

## LSP Keymaps

Defined in `lua/managers/lsp/init.lua` via `LspAttach` autocmd:

| Key | Action |
|---|---|
| `gd` | Go to definition |
| `gr` | Find references |
| `gi` | Go to implementation |
| `K` | Hover documentation (with border + title) |
| `<leader>rn` | Rename symbol |
| `<leader>ca` | Code action |
| `[d` | Previous diagnostic |
| `]d` | Next diagnostic |
| `<leader>e` | Show diagnostic float |

## Adding an LSP Server

1. Add the server name to `ensure_installed` in `lua/plugins/lsp/mason.lua`.
2. Add its configuration in `lua/plugins/lsp/servers.lua`.
3. Restart Neovim.

```lua
-- In servers.lua
return {
  -- ... existing servers
  pyright = {
    settings = {
      python = {
        analysis = { typeCheckingMode = "basic" },
      },
    },
  },
}
```

---

**Next:** [Completion](completion.md)
**See also:** [LSP Flow](../workflows/lsp-flow.md), [Adding Language Support](../development/adding-a-plugin.md)
