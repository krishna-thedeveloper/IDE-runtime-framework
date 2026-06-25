local events = require("managers.events")
local base = require("managers.base")

local notifications = base.create_preset_manager({
    state_file = vim.fn.stdpath("state") .. "/notifications.txt",
    desc = "notifications",
    key = "n",
    cycle_key = "<leader>nn",
    select_key = "<leader>sn",
    default = "rich",
    items = {
        rich = { label = "Rich", opts = {} },
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
    },
    order = { "rich", "minimal", "native" },
    setup = function()
        vim.schedule(function()
            pcall(function()
                local name = notifications.get_active_name()
                if name ~= "rich" then
                    notifications.apply(name)
                end
            end)
        end)
    end,
})

notifications.base_opts = {
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

function notifications.get_preset(name)
    local item = notifications._items[name]
    if not item then
        return nil
    end
    local merged = vim.tbl_deep_extend("force", {}, notifications.base_opts, item.opts)
    return { label = item.label, opts = merged }
end

function notifications.apply(name)
    for i, n in ipairs(notifications._order) do
        if n == name then
            notifications._current_idx = i
            break
        end
    end

    local item = notifications._items[name]
    if not item then
        return
    end

    local merged = vim.tbl_deep_extend("force", {}, notifications.base_opts, item.opts)
    pcall(function()
        require("noice").setup(merged)
    end)

    vim.notify("Notifications: " .. item.label, vim.log.levels.INFO)
    notifications.save(name)
end

events.on("notifications_apply", function(data)
    notifications.apply(data)
end)

return notifications
