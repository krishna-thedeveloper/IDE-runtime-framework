# Dependency Graph

## Plugin Dependencies

```mermaid
graph TD
    subgraph "LSP Stack"
        mason[Mason.nvim]
        mason_lsp[Mason-LSPConfig]
        lspconfig[Nvim-LSPConfig]
        servers[Servers Config]
        mason --> mason_lsp
        mason_lsp --> lspconfig
        lspconfig --> managers_lsp[Managers.LSP]
        managers_lsp --> servers
        managers_lsp --> managers_completion[Managers.Completion]
    end

    subgraph "Completion Stack"
        blink[Blink.Cmp]
        luasnip[LuaSnip]
        snippets[Friendly Snippets]
        blink --> luasnip
        blink --> snippets
        blink --> managers_completion
        managers_completion -->|capabilities| managers_lsp
    end

    subgraph "Picker Stack"
        telescope[Telescope.nvim]
        fzf[Telescope-FZF]
        plenary[Plenary.nvim]
        snacks_picker[Snacks Picker]
        telescope --> plenary
        telescope --> fzf
        fzf --> telescope
        managers_picker[Managers.Picker] --> telescope
        managers_picker --> snacks_picker
    end

    subgraph "UI Stack"
        heirline[Heirline.nvim]
        webdevicons[Nvim-Web-Devicons]
        bufferline[Bufferline.nvim]
        noice[Noice.nvim]
        notify[Nvim-Notify]
        nui[Nui.nvim]
        indent[Indent-Blankline]
        whichkey[Which-Key.nvim]
        trouble[Trouble.nvim]
        dashboard[Snacks Dashboard]

        heirline --> webdevicons
        bufferline --> webdevicons
        noice --> notify
        noice --> nui
    end

    subgraph "Debug Stack"
        dap[Nvim-Dap]
        dapui[Nvim-Dap-UI]
        nio[Nvim-Nio]
        dap --> dapui
        dapui --> nio
    end

    subgraph "Editor"
        comment[Comment.nvim]
        surround[Nvim-Surround]
        minipairs[Mini.Pairs]
        oil[Oil.nvim]
    end

    subgraph "Source Control"
        gitsigns[Gitsigns.nvim]
        persistence[Persistence.nvim]
    end

    subgraph "Language"
        treesitter[Nvim-Treesitter]
    end

    subgraph "Theme"
        catppuccin[Catppuccin]
        tokyonight[Tokyonight]
        kanagawa[Kanagawa]
        onedark[Onedark]
        everforest[Everforest]
        gruvbox[Gruvbox-Material]
        github[Github-Nvim]
    end
```

## Manager Dependencies

```mermaid
graph TD
    events[Events] --> density[Density]
    events --> focus[Focus]
    events --> notifications[Notifications]

    density --> statusline[Statusline]
    density --> indent[Indent-Blankline]
    density --> bufferline[Bufferline.nvim]
    density --> notifications

    focus --> statusline
    focus --> indent
    focus --> bufferline

    notifications --> noice[Noice.nvim]

    picker[Picker Manager] --> telescope_adapter[Adapter: Telescope]
    picker --> snacks_adapter[Adapter: Snacks]

    completion_mgr[Completion Manager] --> blink_adapter[Adapter: Blink.Cmp]

    lsp_mgr[LSP Manager] --> completion_mgr
    lsp_mgr --> servers_config[Servers Config]

    format_mgr[Format Manager] --> conform[Conform.nvim]

    lint_mgr[Lint Manager] --> nvim_lint[Nvim-Lint]

    git_mgr[Git Manager] --> gitsigns[Gitsigns.nvim]
```

## Runtime Dependency Order

| Phase | Module | Depends On |
|---|---|---|
| 0 | `core/options.lua` | nothing |
| 1 | `themes/init.lua` | nothing (discovers at runtime) |
| 2 | `managers/events.lua` | nothing |
| 3 | `managers/density.lua` | events |
| 4 | `managers/focus.lua` | events |
| 5 | `managers/notifications.lua` | events |
| 6 | `managers/completion/init.lua` | nothing (discovers adapters at runtime) |
| 7 | `managers/picker/init.lua` | nothing (discovers adapters at runtime) |
| 8 | `core/keymaps.lua` | themes, density, focus, notifications, completion, picker |
| 9 | `config/lazy.lua` | nothing (bootstraps Lazy.nvim) |
| 10+ | Plugin config functions | various managers |

## Circular Dependency Prevention

The event bus (`managers/events.lua`) prevents circular dependencies. Instead of:

- `density` directly calling `notifications.apply()`

It does:

- `density` calls `events.emit("notifications_apply", ...)`
- `notifications` subscribes to `events.on("notifications_apply", ...)`

This pattern is used for:

- `density → notifications_apply`
- `density → focus_changed`
- `focus → focus_changed`
- `notifications → notifications_apply`

---

**Previous:** [Lazy Loading](lazy-loading.md)
**Next:** [Abstractions](abstractions.md)
