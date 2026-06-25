local M = {
    label = "Telescope",
}

local function cleanup()
    require("managers.plugin_manager").cleanup("telescope.nvim")
    require("managers.plugin_manager").cleanup("telescope-fzf-native.nvim")
end

M.cleanup = cleanup

local function action(name)
    return function(...)
        require("telescope.builtin")[name](...)
    end
end

M.find_files = action("find_files")
M.live_grep = action("live_grep")
M.buffers = action("buffers")
M.oldfiles = action("oldfiles")
M.help_tags = action("help_tags")
M.git_files = action("git_files")
M.git_commits = action("git_commits")

function M.references()
    require("telescope.builtin").lsp_references()
end

return M
