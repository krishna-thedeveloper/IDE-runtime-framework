local events = require("managers.events")
local base = require("managers.base")

local density = base.create_preset_manager({
  state_file = vim.fn.stdpath("state") .. "/density.txt",
  desc = "density",
  key = "u",
  cycle_key = "<leader>uc",
  select_key = "<leader>sd",
  default = "full",
  items = {
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
  },
  order = { "full", "compact", "minimal" },
  setup = function()
    require("managers.focus").setup()
  end,
})

local focus_active = false

events.on("focus_changed", function(data)
  focus_active = data.active
  if not focus_active then
    local name = density.get_cached_name()
    density._apply_profile(name)
  end
end)

function density._apply_profile(name)
  local profile = density._items[name]
  if not profile then
    return
  end

  require("statusline").set_layout(profile.statusline)
  vim.opt.showtabline = profile.bufferline and 2 or 0

  local ok, err = pcall(function()
    local ibl = require("ibl")
    ibl.setup(require("managers.indent").setup_config(profile.indent))
    require("managers.indent").apply_highlights()
  end)
  if not ok then
    vim.notify("Density IBL: " .. tostring(err), vim.log.levels.WARN)
  end

  pcall(function()
    events.emit("notifications_apply", profile.noice)
  end)

  vim.cmd("redrawstatus!")
  vim.notify("Density: " .. profile.label, vim.log.levels.INFO)
end

density.apply_profile = density._apply_profile

function density.apply(name)
  for i, n in ipairs(density._order) do
    if n == name then
      density._current_idx = i
      break
    end
  end
  density.save(name)
  if focus_active then
    return
  end
  density._apply_profile(name)
  events.emit("density_changed", { profile = name })
end

vim.schedule(function()
  local ok, err = pcall(function()
    local name = density.get_active_name()
    if name ~= "full" then
      density.apply(name)
    end
  end)
  if not ok then
    vim.notify("Density restore: " .. tostring(err), vim.log.levels.WARN)
  end
end)

return density
