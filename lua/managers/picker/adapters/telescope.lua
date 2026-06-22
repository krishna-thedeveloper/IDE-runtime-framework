local M = {
  label = "Telescope",
}

local function cleanup()
  for k in pairs(package.loaded) do
    if type(k) == "string" and (k:find("^telescope") or k == "fzf_lib") then
      package.loaded[k] = nil
    end
  end
  local config = require("lazy.core.config")
  local plugin = config.plugins["telescope.nvim"]
  if plugin then
    plugin._.loaded = nil
  end
  local fzf = config.plugins["telescope-fzf-native.nvim"]
  if fzf then
    fzf._.loaded = nil
  end
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
