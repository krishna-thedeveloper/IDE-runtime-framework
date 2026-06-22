local M = {}

local state_dir = vim.fn.stdpath("state")
local state_file = state_dir .. "/density.txt"
local events = require("managers.events")

local profiles = {
  full = {
    statusline = "full",
    bufferline = true,
    indent = true,
    noice = "rich",
    label = "Full IDE",
  },
  compact = {
    statusline = "compact",
    bufferline = true,
    indent = true,
    noice = "minimal",
    label = "Compact",
  },
  minimal = {
    statusline = "minimal",
    bufferline = false,
    indent = false,
    noice = "native",
    label = "Minimal",
  },
}

local profile_order = { "full", "compact", "minimal" }
local current_idx = nil
local focus_active = false

events.on("focus_changed", function(data)
  focus_active = data.active
  if not focus_active then
    local name = M.get_current_name()
    M._apply_visual(name)
  end
end)

function M.get_active_name()
  local f = io.open(state_file, "r")
  if f then
    local name = f:read("*l")
    f:close()
    name = name and vim.trim(name) or ""
    if name and profiles[name] then
      return name
    end
  end
  return "full"
end

function M.get_current_index()
  if not current_idx then
    local name = M.get_active_name()
    for i, pname in ipairs(profile_order) do
      if pname == name then
        current_idx = i
        return i
      end
    end
    current_idx = 1
  end
  return current_idx
end

function M.get_current_name()
  if current_idx then
    return profile_order[current_idx]
  end
  return M.get_active_name()
end

function M._apply_visual(name)
  local profile = profiles[name]
  if not profile then
    return
  end

  require("statusline").set_layout(profile.statusline)
  vim.opt.showtabline = profile.bufferline and 2 or 0

  pcall(function()
    local ibl = require("ibl")
    ibl.setup({
      enabled = profile.indent,
      indent = {
        char = "│",
        tab_char = "│",
        highlight = { "IblIndent", "IblIndent" },
        smart_indent_cap = true,
      },
      scope = {
        enabled = profile.indent,
        show_start = true,
        show_end = true,
        highlight = "IblScope",
        injected_languages = false,
        priority = 500,
      },
      exclude = {
        filetypes = {
          "help", "dashboard", "neo-tree", "Trouble",
          "lazy", "mason", "notify", "noice", "oil",
          "toggleterm", "lspinfo",
        },
      },
    })
  end)

  pcall(function()
    events.emit("notifications_apply", profile.noice)
  end)

  vim.cmd("redrawstatus!")
  vim.notify("Density: " .. profile.label, vim.log.levels.INFO)
end

function M.apply(name)
  local profile = profiles[name]
  if not profile then
    return
  end

  for i, pname in ipairs(profile_order) do
    if pname == name then
      current_idx = i
      break
    end
  end

  M.save(name)

  if focus_active then
    return
  end

  M._apply_visual(name)
  events.emit("density_changed", { profile = name })
end

function M.cycle()
  current_idx = (M.get_current_index() % #profile_order) + 1
  M.apply(profile_order[current_idx])
end

function M.save(name)
  vim.fn.mkdir(state_dir, "p")
  local f = io.open(state_file, "w")
  if f then
    f:write(name)
    f:close()
  end
end

function M.setup()
  local name = M.get_current_name()
  local profile = profiles[name]
  if not profile then
    return
  end
  require("statusline").set_layout(profile.statusline)
  vim.opt.showtabline = profile.bufferline and 2 or 0
end

function M.select()
    require("managers.picker")._load_active()
    vim.ui.select(profile_order, {
        prompt = "Select density",
        format_item = function(item)
            local label = profiles[item].label
            if item == M.get_current_name() then
                return label .. "  ●"
            end
            return label
        end,
    }, function(choice)
        if choice then
            M.apply(choice)
        end
    end)
end

vim.keymap.set("n", "<leader>uc", M.cycle, { desc = "Cycle density" })
vim.keymap.set("n", "<leader>sd", M.select, { desc = "Select density" })

local did_restore = false

vim.schedule(function()
  pcall(function()
    local name = M.get_active_name()
    if not did_restore and name ~= "full" then
      did_restore = true
      M.apply(name)
    end
    did_restore = true
  end)
end)

return M
