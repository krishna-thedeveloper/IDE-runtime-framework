# Which-Key

## Overview

Which-key (`folke/which-key.nvim`) shows a popup of available keymaps when you press a prefix key and wait. It is configured in `lua/plugins/whichkey.lua`.

## Configuration

```lua
opts = {
  preset = "modern",
  icons = { group = "" },
}
```

The `modern` preset provides cleaner popup styling.

## Group Registration

Leader prefix groups are registered in the `config` function:

```lua
wk.add({
  { "<leader>f", group = "Find" },        -- <leader>ff, fg, fb, fo, fh, fp
  { "<leader>g", group = "Git" },         -- <leader>gs, gr, gp, gb, gS, gR, gB, gf, gc
  { "<leader>c", group = "Code" },        -- <leader>ca, cf, cp, cl, cs
  { "<leader>u", group = "UI" },          -- <leader>uc, sd
  { "<leader>n", group = "Notifications" },-- <leader>nn, sn
  { "<leader>d", group = "Debug" },       -- <leader>db, dB, dc, dC, do, di, dO, dr, du, dh
  { "<leader>x", group = "Trouble" },     -- <leader>xx, xX, xL, xQ
  { "<leader>S", group = "Session" },     -- <leader>Ss, Sl, Sd
  { "<leader>s", group = "Select" },      -- <leader>st, sd, sn, sc, sp
})
```

## How It Works

1. User presses `<Space>` (leader).
2. Which-key detects the prefix and shows the popup with all groups.
3. User presses the next key (e.g., `f`).
4. Which-key updates the popup to show all `Find` mappings.
5. User presses the final key (e.g., `f` for find files).

## Adding to Which-Key

When you add a new leader prefix, register it in `lua/plugins/whichkey.lua`:

```lua
-- Add a new group
{ "<leader>m", group = "MyPlugin" },
```

Lazy.nvim automatically integrates with which-key for keymaps defined in plugin specs (the `keys` field).

---

**Previous:** [Leader Mappings](leader-mappings.md)
**Up:** [Keymaps](keymaps-overview.md)
