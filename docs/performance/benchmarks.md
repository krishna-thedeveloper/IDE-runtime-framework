# Benchmarks

> **Note**: Benchmarks vary by machine, OS, and filesystem. These are reference values measured on a modern Linux workstation with an NVMe SSD.

## Startup Time

```bash
nvim --headless +qa
```

| Metric | Target | Typical |
|---|---|---|
| Cold startup (no cache) | < 100ms | 50-80ms |
| Warm startup (cached) | < 60ms | 30-50ms |
| With VeryLazy deferred loaded | < 200ms | 100-150ms |

## Plugin Load Times

```vim
:Lazy profile
```

| Plugin | Time (ms) |
|---|---|
| lazy.nvim bootstrap | 10-20 |
| nvim-treesitter (spec) | 3-5 |
| catppuccin (active) | 15-25 |
| heirline.nvim (VeryLazy) | 5-10 |
| telescope.nvim (on demand) | 15-25 |
| blink.cmp (InsertEnter) | 8-12 |
| noice.nvim (VeryLazy) | 8-15 |

## File Operations

| Operation | Time |
|---|---|
| Open 1000-line file | < 10ms |
| LSP attach + diagnostics | 50-200ms (depends on server) |
| Treesitter highlight (1000-line file) | 5-15ms |
| Picker (find_files, 10k files) | 50-100ms |
| Format on save (conform) | 10-50ms |
| Theme switch | 20-50ms |

## Measuring Yourself

```bash
# Startup time
nvim --headless +qa 2>&1 | rg "startup"

# Profile
nvim --headless "+Lazy! profile" +qa

# Individual plugin load time
nvim --headless -c "lua local s = vim.fn.reltime(); require('plugin'); print(vim.fn.reltimestr(vim.fn.reltime(s)))" -c qa
```

---

**Previous:** [Memory Usage](memory-usage.md)
