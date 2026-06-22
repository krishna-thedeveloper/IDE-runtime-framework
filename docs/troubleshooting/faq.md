# FAQ

## General

### Why is the leader key Space?

Space is the most ergonomic leader key — it's the largest key on the keyboard and doesn't conflict with any default Neovim keymaps.

### Why two pickers (Telescope + Snacks)?

The adapter pattern allows runtime switching. Telescope is mature with a rich extension ecosystem. Snacks is modern, lighter, and has built-in frecency. Users can choose without committing.

### Why not use a single language server config for everything?

Each language server has unique configuration requirements. The `servers.lua` approach keeps server configs declarative and composable alongside the LSP manager.

### Why Heirline over Lualine?

Heirline's component composition model allows dynamic, condition-based layouts that Lualine cannot easily achieve. The density profile system and focus mode rely on this flexibility.

## Runtime Switching

### Can I switch between pickers during a session?

Yes. Press `<leader>fp` to cycle or `<leader>sp` to select from a list. The switch takes effect immediately for the next picker action.

### Can I switch completion engines?

Yes. Press `<leader>cp` to cycle or `<leader>sc` to select. Note that full engine swap requires a session restart for LSP client capability changes.

### Does switching themes lose my plugin highlights?

No. The theme system saves all known plugin highlight groups before switching and restores them after.

## Architecture

### Why not use a single monolithic file?

Modular files provide:
1. **Discoverability** — each concern is findable by name.
2. **Maintainability** — changes to one plugin don't risk breaking others.
3. **Lazy loading** — Lazy.nvim reads per-file specs naturally.
4. **Replaceability** — swap a file, swap a plugin.

### Why managers instead of direct plugin config?

Managers provide:
1. **Abstraction** — swap the underlying plugin without changing keymaps or dependent code.
2. **Cross-cutting concerns** — density touches statusline, bufferline, indent, and notifications simultaneously.
3. **State management** — persistence, restoration, and runtime switching.

### Why an event bus?

The event bus (`managers/events.lua`) prevents circular dependencies between managers. Without it, `density` importing `notifications` and `notifications` potentially importing `density` would create a circular dependency.

### How are themes auto-discovered?

The theme manager reads all `.lua` files in `lua/themes/` (excluding `init.lua`) at startup. Each file returns a list of theme entries. This means adding a new theme is as simple as creating a new file — no registration needed.

---

**Previous:** [Common Issues](common-issues.md)
