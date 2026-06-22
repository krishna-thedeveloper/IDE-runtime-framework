# Editing Plugins

## Comment.nvim

**File:** `lua/plugins/editor.lua`

- **Plugin:** `numToStr/Comment.nvim`
- **Purpose:** Toggle comments with `gc` (operator) and `gcc` (line).
- **Why:** Standard comment toggling with motion support.
- **Alternatives:** `mini.comment`, `commentary`.
- **Configuration:** Defaults (no custom opts).

## nvim-surround

**File:** `lua/plugins/editor.lua`

- **Plugin:** `kylechui/nvim-surround`
- **Purpose:** Add, delete, and change surrounding characters (parentheses, quotes, tags, etc.).
- **Why:** Essential text editing plugin. More modern than `vim-surround` (Lua-based).
- **Alternatives:** `vim-surround` (Vimscript, older), `mini.surround`.
- **Configuration:** Defaults.

Usage: `ys` (add), `ds` (delete), `cs` (change).

## mini.pairs

**File:** `lua/plugins/editor.lua`

- **Plugin:** `echasnovski/mini.pairs`
- **Purpose:** Auto-pair brackets, quotes, and other characters.
- **Why:** Minimal, fast, no configuration needed. Part of the `mini.*` ecosystem which is well-maintained and lightweight.
- **Alternatives:** `nvim-autopairs` (heavier, more configurable), `vim-endwise`.
- **Configuration:** Defaults.

## Oil.nvim

**File:** `lua/plugins/editor.lua`

- **Plugin:** `stevearc/oil.nvim`
- **Purpose:** File explorer as a regular buffer — edit your filesystem like a text file.
- **Why:** More intuitive than traditional tree-based explorers. No separate UI panel needed.
- **Alternatives:** `neo-tree.nvim`, `nvim-tree.lua`.
- **Usage:** `:Oil` to open.

---

**Up:** [Plugin System](plugin-system.md)
