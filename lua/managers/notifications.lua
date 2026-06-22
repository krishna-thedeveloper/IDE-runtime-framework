local M = {}

local state = require("managers.state")
local state_file = vim.fn.stdpath("state") .. "/notifications.txt"
local events = require("managers.events")

M.base_opts = {
  cmdline = {
    enabled = true,
    view = "cmdline_popup",
    format = {
      cmdline = { icon = "" },
      search_down = { icon = " ", lang = "regex" },
      search_up = { icon = " ", lang = "regex" },
      filter = { icon = "$", lang = "bash" },
      lua = { icon = "", lang = "lua" },
      help = { icon = "" },
    },
  },
  messages = {
    enabled = true,
    view = "notify",
    view_error = "notify",
    view_warn = "notify",
    view_history = "messages",
    view_search = "virtualtext",
  },
  popupmenu = {
    enabled = true,
    backend = "nui",
  },
  notify = {
    enabled = true,
    view = "notify",
  },
  lsp = {
    progress = {
      enabled = true,
      format = "lsp_progress",
      format_done = "lsp_progress_done",
      throttle = 1000 / 30,
      view = "mini",
    },
    override = {
      ["vim.lsp.util.convert_input_to_markdown_lines"] = true,
      ["vim.lsp.util.stylize_markdown"] = true,
    },
    hover = {
      enabled = true,
      silent = false,
    },
    signature = {
      enabled = true,
      auto_open = {
        enabled = true,
        trigger = true,
        luasnip = true,
        throttle = 50,
      },
    },
    message = {
      enabled = true,
      view = "notify",
    },
    documentation = {
      view = "hover",
      opts = {
        lang = "markdown",
        replace = true,
        render = "plain",
        format = { "{message}" },
        win_options = { concealcursor = "n", conceallevel = 3 },
      },
    },
  },
  markdown = {
    hover = {
      ["|(%S-)|"] = vim.cmd.help,
      ["%[.-%]%((%S-)%)"] = function(url)
        vim.ui.open(url)
      end,
    },
    highlights = {
      ["|%S-|"] = "@text.reference",
      ["@%S+"] = "@parameter",
      ["^%s*(Parameters:)"] = "@text.title",
      ["^%s*(Return:)"] = "@text.title",
      ["^%s*(See also:)"] = "@text.title",
      ["{%S-}"] = "@parameter",
    },
  },
  presets = {
    bottom_search = true,
    command_palette = true,
    long_message_to_split = true,
    inc_rename = true,
    lsp_doc_border = true,
  },
  throttle = 1000 / 30,
  views = {},
  routes = {},
  status = {},
  format = {},
}

local deltas = {
  rich = {
    label = "Rich",
    opts = {},
  },
  minimal = {
    label = "Minimal",
    opts = {
      messages = { enabled = false },
      popupmenu = { enabled = true, backend = "nui" },
      notify = { enabled = true, view = "mini" },
      lsp = {
        progress = { enabled = false },
        message = { enabled = false },
      },
      presets = {
        command_palette = false,
        long_message_to_split = false,
        inc_rename = false,
      },
    },
  },
  native = {
    label = "Native",
    opts = {
      cmdline = { enabled = false },
      messages = { enabled = false },
      popupmenu = { enabled = false },
      notify = { enabled = false },
      lsp = {
        progress = { enabled = false },
        override = {
          ["vim.lsp.util.convert_input_to_markdown_lines"] = false,
          ["vim.lsp.util.stylize_markdown"] = false,
        },
        hover = { enabled = false },
        signature = { enabled = false },
        message = { enabled = false },
      },
      presets = {
        bottom_search = false,
        command_palette = false,
        long_message_to_split = false,
        inc_rename = false,
      },
    },
  },
}

local preset_order = { "rich", "minimal", "native" }
local current_idx = nil

function M.get_preset(name)
  local delta = deltas[name]
  if not delta then
    return nil
  end
  local opts = vim.tbl_deep_extend("force", {}, M.base_opts, delta.opts)
  return { label = delta.label, opts = opts }
end

function M.get_active_name()
  return state.load(state_file, deltas, "rich")
end

function M.get_current_index()
  if not current_idx then
    local name = M.get_active_name()
    for i, pname in ipairs(preset_order) do
      if pname == name then
        current_idx = i
        return i
      end
    end
    current_idx = 1
  end
  return current_idx
end

function M.apply(name)
  local delta = deltas[name]
  if not delta then
    return
  end

  for i, pname in ipairs(preset_order) do
    if pname == name then
      current_idx = i
      break
    end
  end

  local merged = vim.tbl_deep_extend("force", {}, M.base_opts, delta.opts)
  pcall(function()
    require("noice").setup(merged)
  end)

  vim.notify("Notifications: " .. delta.label, vim.log.levels.INFO)
  M.save(name)
end

function M.cycle()
  current_idx = (M.get_current_index() % #preset_order) + 1
  M.apply(preset_order[current_idx])
end

function M.save(name)
  state.save(name, state_file)
end

events.on("notifications_apply", function(data)
  M.apply(data)
end)

function M.select()
    require("managers.select").select(preset_order, {
        prompt = "Select notifications preset",
        format_item = function(item)
            local label = deltas[item].label
            if item == M.get_active_name() then
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

vim.keymap.set("n", "<leader>nn", M.cycle, { desc = "Cycle notification preset" })
vim.keymap.set("n", "<leader>sn", M.select, { desc = "Select notification preset" })

vim.schedule(function()
  pcall(function()
    local name = M.get_active_name()
    if name ~= "rich" then
      M.apply(name)
    end
  end)
end)

return M
