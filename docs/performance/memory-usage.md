# Memory Usage

## Strategy

Memory is managed through three mechanisms:

1. **Lazy loading** — plugins only occupy memory when their trigger fires.
2. **Post-action cleanup** — picker plugins unload after use.
3. **Selective theme loading** — only the active colorscheme plugin is loaded.

## Plugin Memory Footprint (Approximate)

| Plugin | Memory (est.) | When Loaded |
|---|---|---|
| nvim-treesitter | ~5-15MB (parsers are large C libs) | Always |
| telescope.nvim | ~2-3MB | On picker invocation |
| blink.cmp | ~1-2MB | On InsertEnter |
| noice.nvim | ~1-2MB | On VeryLazy |
| heirline.nvim | ~500KB | On VeryLazy |
| nvim-lspconfig | ~500KB | On BufReadPre |
| gitsigns.nvim | ~500KB | On BufRead |
| Colorscheme | ~500KB-2MB | Only active theme |

## Cleanup Mechanism

The picker adapter system unloads Telescope/Snacks after each use:

```lua
for k in pairs(package.loaded) do
  if type(k) == "string" and (k:find("^telescope") or k == "fzf_lib") then
    package.loaded[k] = nil
  end
end
```

This reduces resident memory after a picker action by ~3-5MB.

## What Stays in Memory

Once loaded, the following remain resident for the session:

- LSP clients and their associated data.
- Treesitter parsers (loaded per-buffer).
- Completion engine (blink.cmp) meta state.
- Manager state caches.

---

**Previous:** [Lazy Loading Strategy](lazy-loading-strategy.md)
