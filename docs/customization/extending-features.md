# Extending Features

## Adding a New Picker Method

### 1. Add to all adapter files

```lua
-- lua/managers/picker/adapters/telescope.lua
M.git_branches = action("git_branches")

-- lua/managers/picker/adapters/snacks.lua
M.git_branches = action("git_branches", "git_branches")
```

### 2. Register the proxy method

```lua
-- In lua/managers/picker/init.lua, add to `methods` list:
local methods = {
  "find_files", "live_grep", "buffers", "oldfiles",
  "help_tags", "git_files", "git_commits", "references",
  "git_branches",   -- new
}
```

### 3. Add a keymap

```lua
-- In lua/core/keymaps.lua
vim.keymap.set("n", "<leader>gb", picker.git_branches, { desc = "Git branches" })
```

Auto-generated proxy functions handle the rest.

## Adding a New Density Profile

```lua
-- In lua/managers/density.lua, add to `profiles` table:
profiles = {
  -- existing profiles...
  coding = {
    statusline = "compact",
    bufferline = true,
    indent = true,
    noice = "rich",
    label = "Coding",
  },
}

-- Add to profile_order
local profile_order = { "full", "compact", "coding", "minimal" }
```

## Adding a New Notification Preset

```lua
-- In lua/managers/notifications.lua, add to `deltas` table:
deltas = {
  -- existing presets...
  custom = {
    label = "Custom",
    opts = {
      cmdline = { enabled = true },
      messages = { enabled = true, view = "mini" },
      notify = { enabled = true, view = "mini" },
      lsp = {
        progress = { enabled = false },
        hover = { enabled = true },
      },
    },
  },
}

-- Add to preset_order
local preset_order = { "rich", "minimal", "custom", "native" }
```

## Adding a Statusline Component

```lua
-- In lua/statusline/init.lua
local CursorWord = {
  provider = function()
    local word = vim.fn.expand("<cword>")
    return word ~= "" and " " .. word .. " " or ""
  end,
  hl = function() return { fg = palette.cyan } end,
}

-- Add to components table
local components = {
  -- existing components...
  CursorWord = CursorWord,
}

-- Add to a layout
local layouts = {
  full = {
    active = {
      "ViMode", "FileNameBlock", "Align",
      "CursorWord",              -- new
      "LSPActive", "Diagnostics",
      "GitBranch", "GitChanges",
      "FileEncoding", "Ruler", "Scrollbar",
    },
    -- ...
  },
}
```

---

**Previous:** [Creating Modules](creating-modules.md)
