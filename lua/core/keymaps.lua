require("themes")
require("managers.density")
require("managers.focus")
require("managers.notifications")
require("managers.completion")

local picker = require("managers.picker")

vim.keymap.set("n", "<leader>w", "<cmd>update<CR>", { desc = "Save file" })
vim.keymap.set("n", "<leader>q", "<cmd>q<CR>", { desc = "Close window" })

vim.keymap.set("n", "<leader>ff", picker.find_files, { desc = "Find files" })
vim.keymap.set("n", "<leader>fg", picker.live_grep, { desc = "Live grep" })
vim.keymap.set("n", "<leader>fb", picker.buffers, { desc = "Find buffers" })
vim.keymap.set("n", "<leader>fo", picker.oldfiles, { desc = "Find old files" })
vim.keymap.set("n", "<leader>fh", picker.help_tags, { desc = "Help tags" })
vim.keymap.set("n", "<leader>gf", picker.git_files, { desc = "Git files" })
vim.keymap.set("n", "<leader>gc", picker.git_commits, { desc = "Git commits" })
