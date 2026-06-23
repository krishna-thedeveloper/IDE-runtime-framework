local M = {}

local palette = require("managers.theme").palette

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

local FileIcon = {
    init = function(self)
        local ok, devicons = pcall(require, "nvim-web-devicons")
        if ok then
            local icon, color = devicons.get_icon_colors_by_filetype(vim.bo.filetype)
            if icon then
                self.icon = icon
                self.fg = color
                return
            end
        end
        self.icon = ""
        self.fg = palette.gray
    end,
    provider = function(self)
        return self.icon .. " "
    end,
    hl = function(self)
        return { fg = self.fg }
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
    condition = function() return require("heirline.conditions").is_git_repo end,
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
    condition = function() return require("heirline.conditions").is_git_repo end,
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
        self.errors = 0
        self.warnings = 0
        self.hints = 0
        for _, d in ipairs(vim.diagnostic.get(0)) do
            if d.severity == vim.diagnostic.severity.ERROR then
                self.errors = self.errors + 1
            elseif d.severity == vim.diagnostic.severity.WARN then
                self.warnings = self.warnings + 1
            elseif d.severity == vim.diagnostic.severity.HINT then
                self.hints = self.hints + 1
            end
        end
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
    condition = function() return require("heirline.conditions").lsp_attached end,
    update = { "LspAttach", "LspDetach" },
    init = function(self)
        local clients = vim.lsp.get_clients({ bufnr = 0 })
        local names = vim.tbl_map(function(c)
            return c.name
        end, clients)
        self._names = table.concat(names, ",")
    end,
    provider = function(self)
        return self._names and (" 󰒋 " .. self._names .. " ") or ""
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

local components = {
    ViMode = ViMode,
    FileNameBlock = FileNameBlock,
    Align = Align,
    LSPActive = LSPActive,
    Diagnostics = Diagnostics,
    GitBranch = GitBranch,
    GitChanges = GitChanges,
    FileEncoding = FileEncoding,
    Ruler = Ruler,
    Scrollbar = Scrollbar,
}

local function make_layout(names)
    local items = {}
    for _, name in ipairs(names) do
        if components[name] then
            table.insert(items, components[name])
        end
    end
    return items
end

local function prepend_condition(items, condition_fn)
    local result = { condition = condition_fn }
    for _, item in ipairs(items) do
        table.insert(result, item)
    end
    return result
end

local layouts = {
    full = {
        active = {
            "ViMode", "FileNameBlock", "Align",
            "LSPActive", "Diagnostics",
            "GitBranch", "GitChanges",
            "FileEncoding", "Ruler", "Scrollbar",
        },
        special = { "FileNameBlock", "Align" },
        inactive = { "FileNameBlock", "Align" },
    },
    compact = {
        active = {
            "FileNameBlock", "Align",
            "Diagnostics", "Ruler", "Scrollbar",
        },
        special = { "FileNameBlock", "Align" },
        inactive = { "FileNameBlock", "Align" },
    },
    minimal = {
        active = { "FileNameBlock", "Align", "Ruler" },
        special = { "FileNameBlock", "Align" },
        inactive = { "FileNameBlock", "Align" },
    },
}

function M.set_layout(name)
    local layout = layouts[name]
    if not layout then
        return
    end

    local hl = require("heirline")
    local cond = require("heirline.conditions")

    local active = make_layout(layout.active)
    local special = prepend_condition(make_layout(layout.special or layout.active), function()
        return cond.buffer_matches({
            buftype = { "terminal", "nofile", "prompt", "help" },
            filetype = { "Trouble", "noice", "neo-tree", "lazy" },
        })
    end)
    local inactive = prepend_condition(
        vim.list_extend(make_layout(layout.inactive or layout.active), {
            { provider = " Inactive ", hl = function() return { fg = palette.gray } end },
        }),
        cond.is_not_active
    )

    hl.setup({ statusline = { special, inactive, active } })
end

function M.layout_names()
    local names = {}
    for name in pairs(layouts) do
        table.insert(names, name)
    end
    table.sort(names)
    return names
end

return M
