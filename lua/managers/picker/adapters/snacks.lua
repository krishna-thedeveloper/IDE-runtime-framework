local M = {
    label = "Snacks",
}

local function cleanup()
    require("managers.plugin_manager").cleanup("snacks.nvim")
end

M.cleanup = cleanup

local function action(name, snack_name)
    return function(...)
        require("snacks").picker[snack_name or name](...)
    end
end

M.find_files = action("files")
M.live_grep = action("grep")
M.buffers = action("buffers")
M.oldfiles = action("recent")
M.help_tags = action("help")
M.git_files = action("git_files")
M.git_commits = action("git_log")

function M.references()
    require("snacks").picker.lsp_references()
end

return M
