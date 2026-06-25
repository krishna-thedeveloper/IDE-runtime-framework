# Debugging

## Common Debugging Techniques

### Check Plugin Loading

```vim
:Lazy                    " View plugin status
:Lazy log                " View Lazy.nvim log
:Lazy debug <plugin>     " Debug a specific plugin
```

### Check Plugin Load State

```lua
:lua print(vim.inspect(require("lazy.core.config").plugins["plugin-name"]))
```

### Check Module Caching

```lua
:lua print(vim.inspect(package.loaded["plugin-name"]))
```

### Profile Startup

```vim
:Lazy profile           " Show startup profiling
:Lazy profile --local   " Show local plugin times
```

See [Profiling](profiling.md) for detailed instructions.

### Check LSP Status

```vim
:LspInfo                " Show LSP client status
:LspLog                 " View LSP log
```

### Check Keymap Conflicts

```vim
:verbose nmap <leader>ff   " Show what <leader>ff is mapped to
:map <leader>              " List all leader mappings
```

### Check Autocommands

```vim
:autocmd User               " List user autocommands
:autocmd LspAttach          " List LSP attach events
```

## Debugging Manager Modules

### Event Bus

Check if events are being emitted correctly:

```lua
:lua require("managers.events").emit("density_changed", { profile = "minimal" })
```

### Picker Adapter

```lua
:lua print(vim.inspect(require("managers.picker")._adapters))
:lua print(require("managers.picker").get_active_name())
```

### Theme System

```lua
:lua print(vim.inspect(require("managers.theme")._order))
:lua print(require("managers.theme").get_active_name())
```

## Debugging with Logs

Add temporary debug output:

```lua
vim.notify("DEBUG: value = " .. vim.inspect(value), vim.log.levels.DEBUG)
```

Or write to a file:

```lua
local f = io.open("/tmp/nvim-debug.log", "a")
f:write("DEBUG: " .. vim.inspect(value) .. "\n")
f:close()
```

## Common Issues

| Symptom | Check |
|---|---|
| Keymap not working | `:verbose nmap <keys>`, check `desc` conflict |
| Plugin not loaded | `:Lazy`, check if trigger event occurred |
| LSP not attaching | `:LspInfo`, check server installation via `:Mason` |
| Highlights broken after theme switch | Check `PLUGIN_PREFIXES` in `lua/managers/theme.lua` |
| Manager not switching | Check `state/<name>.txt` file, check adapter registration |
| Formatting not happening | `:ConformInfo`, check formatter availability |
| Linting not happening | Check lint configuration and linter availability |

---

**Previous:** [Naming Conventions](naming-conventions.md)
**Next:** [Profiling](profiling.md)
