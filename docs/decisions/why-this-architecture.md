# Why This Architecture

## Design Goals

The architecture was designed around these goals, in priority order:

1. **Long-term maintainability** — The configuration should be easy to understand and modify 12 months from now.
2. **Runtime flexibility** — The user should be able to change major aspects (pickers, completion, UI density) without editing config files or restarting.
3. **Minimal startup impact** — Only load what's needed for the first keystroke.
4. **Plugin replaceability** — Swapping a plugin should not require rewriting keymaps or dependent configurations.
5. **Discoverability** — New contributors should understand the structure by looking at the directory tree.

## Why Not a Single File

Single-file configurations (common in the Neovim community) are simple but break down at scale:

- **Plugin specs** become an unorganized list of 30+ entries.
- **Keymaps** are scattered and hard to find.
- **Lazy-loading triggers** are mixed with configuration logic.
- **Cross-cutting concerns** (like UI density) require modifying multiple unrelated sections.

## Why Managers

The manager layer is the key architectural innovation:

```
User Keymaps → Manager API → Plugin A  (swappable)
                            → Plugin B  (alternative)
```

Without managers, the dependency is:

```
User Keymaps → Plugin A  (hardcoded)
```

Replacing Plugin A requires:
1. Finding all keymaps that reference it.
2. Updating each keymap to use Plugin B's API.
3. Changing the plugin spec.

With managers, replacing Plugin A requires:
1. Writing an adapter for Plugin B.
2. Updating the plugin spec.

Everything else stays the same.

## Why Adapter Pattern

The adapter pattern (used for pickers and completion) provides:

- **Runtime switching** — adapters can be swapped via keymaps.
- **Clean interface** — each adapter implements exactly the same methods.
- **Automatic discovery** — adding a new adapter is as simple as creating a file.
- **Post-action cleanup** — adapters can unload themselves to save memory.

## Why Event Bus

The event bus solves a specific problem: **circular dependency prevention between managers**.

- `density` needs to change notification preset → emits `notifications_apply` event.
- `focus` needs to tell density to defer → emits `focus_changed` event.
- `notifications` needs to react to density → listens for `notifications_apply` event.

Without the event bus:

- `density` imports `notifications` → works.
- `notifications` imports `density` → circular dependency.
- Solution: two-way coupling or merging managers.

With the event bus:

- `density` imports `events` (emits).
- `notifications` imports `events` (listens).
- No circular dependency.

## Why Three Density Profiles

The density profiles (Full / Compact / Minimal) emerged from the observation that:

- **Full**: Everything visible, maximum information density.
- **Compact**: Common middle ground, some UI removed.
- **Minimal**: Distraction-free editing.

Each profile coordinates multiple UI subsystems simultaneously. This is a cross-cutting concern that no single plugin can handle — hence the manager.

## Why Plugin Groups

The `lua/plugins/lsp/` directory groups related plugins:

- **mason.nvim** — package manager.
- **mason-lspconfig.nvim** — bridge between mason and lspconfig.
- **nvim-lspconfig** — LSP configuration.
- **servers.lua** — server definitions.

This keeps all LSP-related concerns in one place, making it easy to understand the full LSP setup without jumping between files.

## Why the Palette System

The statusline palette (`themes.init.palette`) is extracted from the theme's highlight groups rather than hardcoded. This means:

1. When the theme changes, the statusline automatically adapts.
2. Each statusline component gets consistent colors.
3. Theme authors don't need to configure statusline colors separately.

## Why Post-Action Cleanup

Picker adapters unload themselves after use. This is an unusual pattern in Neovim, justified by:

- Telescope pulls in ~20+ modules (~2-3MB memory).
- Most of the session doesn't use the picker.
- Loading on-demand + unloading keeps memory profile lean.

## Why Not Some Popular Choices

### Why not nvim-cmp?

- nvim-cmp is slower than blink.cmp.
- nvim-cmp's configuration is more verbose.
- blink.cmp is the direction the Neovim community is moving.

### Why not lazy.nvim's built-in keymap handling (more)?

Lazy.nvim's `keys` field is used for plugins that need lazy-loading via keypress (e.g., nvim-dap). For global leader maps, explicit `vim.keymap.set` is used because:

- Leader maps need to be available immediately, not after plugin load.
- Global maps are not tied to a specific plugin.
- Explicit keymaps are easier to find and audit.

### Why not use snacks.nvim for everything (like the dashboard)?

Snacks.nvim is used for the dashboard and as a picker option, but not for everything. The configuration prefers specialized plugins (Telescope for search, Heirline for statusline, bufferline for tabs) because:

- Specialized plugins are deeper and more configurable in their domain.
- Using a single framework creates a single point of failure.
- Mixing ecosystems provides a richer feature set.

---

**Next:** [Plugin Comparisons](plugin-comparisons.md)
