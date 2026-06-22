# Common Issues

## Lazy.nvim

### "Failed to clone lazy.nvim"

**Cause:** No internet connection or git not installed.

**Solution:** Check git is installed (`git --version`) and network connectivity.

### Plugin not loading

**Cause:** Trigger event hasn't fired, or loading condition isn't met.

**Solution:** Check `:Lazy` to see if the plugin is loaded. Manually trigger it: `:lua require("plugin-name")`.

### "Cannot find module" error

**Cause:** Typo in `require` path, or plugin not installed.

**Solution:** Verify the module path matches the file structure. Run `:Lazy sync` to ensure all plugins are installed.

## LSP

### LSP not attaching to buffers

**Cause:** Server not installed, misconfigured, or not enabled.

**Solution:**
1. `:Mason` — check server installation.
2. `:LspInfo` — see attached clients.
3. Check `lua/plugins/lsp/servers.lua` for server config.
4. Verify server binary is on `$PATH` or installed via mason.

### Completion not working

**Cause:** LSP capabilities not set, or completion engine not active.

**Solution:**
1. Ensure LSP is attached (`:LspInfo`).
2. Check adapter state: `:lua print(require("managers.completion").get_active_name())`.
3. Verify blink.cmp configuration.

## Themes

### Theme switch breaks plugin highlights

**Cause:** A plugin prefix is missing from `PLUGIN_PREFIXES` in `lua/themes/init.lua`.

**Solution:** Add the plugin's highlight prefix to the list:

```lua
local PLUGIN_PREFIXES = {
  -- ... existing prefixes
  "NewPlugin",
}
```

### Theme not appearing in cycle/select

**Cause:** Theme file has a syntax error or doesn't return a valid entry table.

**Solution:** Check `:lua print(vim.inspect(require("themes").themes))` to see registered themes. Check the theme file for errors.

### Statusline colors wrong after theme switch

**Cause:** Palette extraction failed (highlight groups not found).

**Solution:** Verify `M.update_palette()` is called after theme apply. Check the fallback colors in `default_palette`.

## Performance

### Slow startup

**Cause:** Plugin loading eagerly that shouldn't be.

**Solution:**
1. `:Lazy profile` to identify slow plugins.
2. Check if the plugin spec has `lazy = false`.
3. Move to `VeryLazy` event if possible.

### High memory usage

**Cause:** Many LSP clients or large Treesitter parsers.

**Solution:**
1. Check `:LspInfo` for unnecessary servers.
2. Reduce `ensure_installed` in treesitter config.

## Managers

### Picker/Completion switch not working

**Cause:** Adapter not found or not registered.

**Solution:**
1. Check `:lua print(vim.inspect(require("managers.picker")._adapters))`.
2. Verify adapter file exists in the `adapters/` directory.
3. Check that the adapter returns a valid table.

### Manager state not persisting

**Cause:** State file directory not writable.

**Solution:** Ensure `vim.fn.stdpath("state")` exists and is writable. The `vim.fn.mkdir(state_dir, "p")` call in each manager should handle this.

## Plugins

### Formatting not working

**Cause:** Formatter not installed or not on `$PATH`.

**Solution:**
1. `:ConformInfo` to see available formatters.
2. Install the formatter (e.g., `npm install -g prettier`).
3. Check `formatters_by_ft` in `lua/plugins/formatting.lua`.

### Linting not working

**Cause:** Linter not installed, or not in `linters_by_ft`.

**Solution:**
1. Check `lua/plugins/linting.lua` for linter configuration.
2. Install the linter binary.
3. Check `lua/managers/lint/init.lua` for the availability check.

### DAP not working

**Cause:** No debug adapter configured for the language.

**Solution:** Debug adapters are language-specific and need to be configured. See [DAP Plugin](../plugins/dap.md) for examples.

---

**Next:** [FAQ](faq.md)
