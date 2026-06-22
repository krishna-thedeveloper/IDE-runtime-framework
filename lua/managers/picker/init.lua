local base = require("managers.base")

local methods = {
  "find_files", "live_grep", "buffers", "oldfiles",
  "help_tags", "git_files", "git_commits", "references",
}

return base.create_adapter_manager({
  state_file = vim.fn.stdpath("state") .. "/picker.txt",
  adapter_prefix = "managers.picker.adapters",
  desc = "Picker",
  key = "p",
  methods = methods,
})
