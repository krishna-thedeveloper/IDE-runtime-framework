local M = {}

local state = require("managers.state")
local state_file = vim.fn.stdpath("state") .. "/density.txt"
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
    M.apply_profile(name)
  end
end)

function M.get_active_name()
  return state.load(state_file, profiles, "full")
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

function M.apply_profile(name)
  local profile = profiles[name]
  if not profile then
    return
  end

  require("statusline").set_layout(profile.statusline)
  vim.opt.showtabline = profile.bufferline and 2 or 0

  pcall(function()
    local ibl = require("ibl")
    ibl.setup(require("managers.indent").setup_config(profile.indent))
    require("managers.indent").apply_highlights()
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

  M.apply_profile(name)
  events.emit("density_changed", { profile = name })
end

function M.cycle()
  current_idx = (M.get_current_index() % #profile_order) + 1
  M.apply(profile_order[current_idx])
end

function M.save(name)
  state.save(name, state_file)
end

function M.setup()
  if current_idx then
    return
  end
  local name = M.get_current_name()
  local profile = profiles[name]
  if not profile then
    return
  end
  require("statusline").set_layout(profile.statusline)
  vim.opt.showtabline = profile.bufferline and 2 or 0
end

function M.select()
    require("managers.select").select(profile_order, {
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
