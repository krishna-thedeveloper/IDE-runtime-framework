return {
    {
        "rebelot/heirline.nvim",
        event = "VeryLazy",
        dependencies = { "nvim-tree/nvim-web-devicons" },
        config = function()
            local heirline = require("heirline")
            local conditions = require("heirline.conditions")
            local palette = require("themes").palette

            local ViMode = {
                static = {
                    mode_names = {
                        n = "NORMAL",
                        i = "INSERT",
                        v = "VISUAL",
                        V = "VISUAL",
                        ["\22"] = "VISUAL",
                        c = "COMMAND",
                        s = "SELECT",
                        S = "SELECT",
                        t = "TERMINAL",
                        R = "REPLACE",
                        r = "PROMPT",
                        ["!"] = "SHELL",
                    },
                    mode_colors = {
                        n = function() return palette.green end,
                        i = function() return palette.blue end,
                        v = function() return palette.purple end,
                        V = function() return palette.purple end,
                        ["\22"] = function() return palette.purple end,
                        c = function() return palette.yellow end,
                        s = function() return palette.cyan end,
                        S = function() return palette.cyan end,
                        t = function() return palette.red end,
                        R = function() return palette.yellow end,
                        r = function() return palette.cyan end,
                        ["!"] = function() return palette.red end,
                    },
                },
                provider = function(self)
                    local mode = vim.fn.mode()
                    return " " .. (self.mode_names[mode] or mode) .. " "
                end,
                hl = function(self)
                    local mode = vim.fn.mode()
                    return { fg = palette.dark_bg, bg = self.mode_colors[mode](), bold = true }
                end,
                update = { "ModeChanged" },
            }

            local function get_file_icon()
                local ok, devicons = pcall(require, "nvim-web-devicons")
                if ok then
                    local icon, color = devicons.get_icon_colors_by_filetype(vim.bo.filetype)
                    if icon then
                        return icon, color
                    end
                end
                return "", palette.gray
            end

            local FileIcon = {
                provider = function()
                    local icon = get_file_icon()
                    return icon .. " "
                end,
                hl = function()
                    local _, color = get_file_icon()
                    return { fg = color }
                end,
            }

            local FileName = {
                provider = function()
                    local name = vim.api.nvim_buf_get_name(0)
                    if name == "" then
                        return "[No Name]"
                    end
                    return vim.fn.fnamemodify(name, ":~:.")
                end,
                hl = function() return { fg = palette.white } end,
            }

            local FileModified = {
                condition = function()
                    return vim.bo.modified
                end,
                provider = "  ",
                hl = function() return { fg = palette.blue } end,
            }

            local FileReadOnly = {
                condition = function()
                    return vim.bo.readonly or not vim.bo.modifiable
                end,
                provider = "  ",
                hl = function() return { fg = palette.red } end,
            }

            local FileNameBlock = {
                FileIcon,
                FileName,
                FileModified,
                FileReadOnly,
            }

            local GitBranch = {
                condition = conditions.is_git_repo,
                init = function(self)
                    local gitsigns = package.loaded.gitsigns
                    if gitsigns then
                        local ok, head = pcall(gitsigns.get_head)
                        self.head = ok and head or ""
                    else
                        self.head = ""
                    end
                end,
                provider = function(self)
                    if self.head and self.head ~= "" then
                        return "  " .. self.head .. " "
                    end
                    return ""
                end,
                hl = function() return { fg = palette.purple } end,
            }

            local GitChanges = {
                condition = conditions.is_git_repo,
                init = function(self)
                    local gitsigns = package.loaded.gitsigns
                    if gitsigns then
                        local ok, dict = pcall(gitsigns.get_dict)
                        self.dict = ok and dict or {}
                    else
                        self.dict = {}
                    end
                end,
                provider = function(self)
                    local parts = {}
                    if self.dict.added and self.dict.added > 0 then
                        table.insert(parts, "+" .. self.dict.added)
                    end
                    if self.dict.changed and self.dict.changed > 0 then
                        table.insert(parts, "~" .. self.dict.changed)
                    end
                    if self.dict.removed and self.dict.removed > 0 then
                        table.insert(parts, "-" .. self.dict.removed)
                    end
                    if #parts > 0 then
                        return " [" .. table.concat(parts, " ") .. "] "
                    end
                    return ""
                end,
                hl = function() return { fg = palette.gray } end,
            }

            local Diagnostics = {
                condition = function()
                    return #vim.diagnostic.get(0) > 0
                end,
                init = function(self)
                    self.errors = #vim.diagnostic.get(0, { severity = vim.diagnostic.severity.ERROR })
                    self.warnings = #vim.diagnostic.get(0, { severity = vim.diagnostic.severity.WARN })
                    self.hints = #vim.diagnostic.get(0, { severity = vim.diagnostic.severity.HINT })
                end,
                {
                    provider = function(self)
                        return self.errors > 0 and (" " .. self.errors .. " ") or ""
                    end,
                    hl = function() return { fg = palette.red } end,
                },
                {
                    provider = function(self)
                        return self.warnings > 0 and (" " .. self.warnings .. " ") or ""
                    end,
                    hl = function() return { fg = palette.yellow } end,
                },
                {
                    provider = function(self)
                        return self.hints > 0 and (" " .. self.hints .. " ") or ""
                    end,
                    hl = function() return { fg = palette.cyan } end,
                },
                update = { "DiagnosticChanged", "BufEnter" },
            }

            local LSPActive = {
                condition = conditions.lsp_attached,
                update = { "LspAttach", "LspDetach" },
                provider = function()
                    local clients = vim.lsp.get_clients({ bufnr = 0 })
                    local names = vim.tbl_map(function(c)
                        return c.name
                    end, clients)
                    return " 󰒋 " .. table.concat(names, ",") .. " "
                end,
                hl = function() return { fg = palette.blue } end,
            }

            local FileEncoding = {
                provider = function()
                    local enc = vim.bo.fileencoding or vim.o.encoding
                    return " " .. (enc and enc:upper() or "UTF-8") .. " "
                end,
                hl = function() return { fg = palette.gray } end,
            }

            local Ruler = {
                provider = "%l:%c",
                hl = function() return { fg = palette.white } end,
            }

            local Scrollbar = {
                provider = " %p%% ",
                hl = function() return { fg = palette.gray } end,
            }

            local Align = { provider = "%=" }

            local DefaultStatusline = {
                ViMode,
                FileNameBlock,
                Align,
                LSPActive,
                Diagnostics,
                GitBranch,
                GitChanges,
                FileEncoding,
                Ruler,
                Scrollbar,
            }

            local SpecialStatusline = {
                condition = function()
                    return conditions.buffer_matches({
                        buftype = { "terminal", "nofile", "prompt", "help" },
                        filetype = { "Trouble", "noice", "neo-tree", "lazy" },
                    })
                end,
                FileNameBlock,
                Align,
                { provider = " %p%% ", hl = function() return { fg = palette.gray } end },
            }

            local InactiveStatusline = {
                condition = conditions.is_not_active,
                FileNameBlock,
                Align,
                { provider = " Inactive ", hl = function() return { fg = palette.gray } end },
            }

            heirline.setup({
                statusline = { SpecialStatusline, InactiveStatusline, DefaultStatusline },
            })
        end,
    },
}
