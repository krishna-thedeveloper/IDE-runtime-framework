local M = {}

local state_dir = vim.fn.stdpath("state")
local state_file = state_dir .. "/notifications.txt"

local presets = {
    rich = {
        label = "Rich",
        opts = {
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
        },
    },
    minimal = {
        label = "Minimal",
        opts = {
            cmdline = {
                enabled = true,
                view = "cmdline_popup",
            },
            messages = {
                enabled = false,
            },
            popupmenu = {
                enabled = true,
                backend = "nui",
            },
            notify = {
                enabled = true,
                view = "mini",
            },
            lsp = {
                progress = {
                    enabled = false,
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
                    enabled = false,
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
            presets = {
                bottom_search = true,
                command_palette = false,
                long_message_to_split = false,
                inc_rename = false,
                lsp_doc_border = true,
            },
            throttle = 1000 / 30,
            views = {},
            routes = {},
            status = {},
            format = {},
        },
    },
    native = {
        label = "Native",
        opts = {
            cmdline = {
                enabled = false,
            },
            messages = {
                enabled = false,
            },
            popupmenu = {
                enabled = false,
            },
            notify = {
                enabled = false,
            },
            lsp = {
                progress = {
                    enabled = false,
                },
                override = {
                    ["vim.lsp.util.convert_input_to_markdown_lines"] = false,
                    ["vim.lsp.util.stylize_markdown"] = false,
                },
                hover = {
                    enabled = false,
                },
                signature = {
                    enabled = false,
                },
                message = {
                    enabled = false,
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
            presets = {
                bottom_search = false,
                command_palette = false,
                long_message_to_split = false,
                inc_rename = false,
                lsp_doc_border = true,
            },
            throttle = 1000 / 30,
            views = {},
            routes = {},
            status = {},
            format = {},
        },
    },
}

local preset_order = { "rich", "minimal", "native" }
local current_idx = nil

function M.get_preset(name)
    return presets[name]
end

function M.get_active_name()
    local f = io.open(state_file, "r")
    if f then
        local name = f:read("*l")
        f:close()
        name = name and vim.trim(name) or ""
        if name and presets[name] then
            return name
        end
    end
    return "rich"
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
    local preset = presets[name]
    if not preset then
        return
    end

    for i, pname in ipairs(preset_order) do
        if pname == name then
            current_idx = i
            break
        end
    end

    pcall(function()
        require("noice").setup(preset.opts)
    end)

    vim.notify("Notifications: " .. preset.label, vim.log.levels.INFO)
    M.save(name)
end

function M.cycle()
    current_idx = (M.get_current_index() % #preset_order) + 1
    M.apply(preset_order[current_idx])
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
    local name = M.get_active_name()
    for i, pname in ipairs(preset_order) do
        if pname == name then
            current_idx = i
            break
        end
    end
end

vim.keymap.set("n", "<leader>nn", M.cycle, { desc = "Cycle notification preset" })

vim.schedule(function()
    pcall(function()
        local name = M.get_active_name()
        if name ~= "rich" then
            M.apply(name)
        end
    end)
end)

return M
