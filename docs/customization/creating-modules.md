# Creating Modules

## Manager Pattern

To create a new manager module (e.g., a "word count" manager):

### 1. Create the file

```lua
-- lua/managers/wordcount.lua
local M = {}

local state_dir = vim.fn.stdpath("state")

function M.get_count()
  local word_count = vim.fn.wordcount()
  return word_count.words
end

function M.toggle()
  -- Toggle word count display
end

-- Register keymap
vim.keymap.set("n", "<leader>cw", M.toggle, { desc = "Toggle word count" })

return M
```

### 2. Load it

Add it to `lua/core/keymaps.lua`:

```lua
require("managers.wordcount")
```

### 3. Integrate with Statusline

Add a component in `lua/statusline/init.lua`:

```lua
local WordCount = {
  provider = function()
    return " " .. require("managers.wordcount").get_count() .. " words "
  end,
  hl = function() return { fg = palette.gray } end,
}
```

Then add it to desired layouts.

## Adapter Pattern

To create a new adapter (e.g., a new picker backend):

### 1. Create the adapter file

```lua
-- lua/managers/picker/adapters/fzf_lua.lua
local M = {
  label = "FzfLua",
}

local function cleanup()
  -- Unload fzf-lua modules from package.loaded
end

M.cleanup = cleanup

M.find_files = function(...)
  require("fzf-lua").files(...)
  cleanup()
end

M.live_grep = function(...)
  require("fzf-lua").grep(...)
  cleanup()
end

M.buffers = function(...)
  require("fzf-lua").buffers(...)
  cleanup()
end

-- Implement all required methods (see abstraction docs for full interface)

return M
```

### 2. Register the plugin spec

```lua
-- lua/plugins/fzf_lua.lua
return {
  {
    "ibhagwan/fzf-lua",
    lazy = true,
  },
}
```

The adapter is auto-discovered at startup.

## Theme Variant Pattern

### 1. Create the theme file

```lua
-- lua/themes/oxocarbon.lua
return {
  {
    name = "oxocarbon",
    plugin = "oxocarbon.nvim",
    group = "oxocarbon",
    apply = function()
      vim.cmd.colorscheme("oxocarbon")
    end,
  },
}
```

### 2. Register the plugin spec

```lua
-- In lua/plugins/colorschemes.lua
{
  "nyoom-engineering/oxocarbon.nvim",
  lazy = active_group ~= "oxocarbon",
  priority = 1000,
  config = delegate("oxocarbon"),
},
```

---

**Previous:** [Overriding Configurations](overriding-configurations.md)
**Next:** [Extending Features](extending-features.md)
