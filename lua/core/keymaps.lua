vim.keymap.set("n", "<leader>w", "<cmd>update<CR>", { desc = "Save file" })
vim.keymap.set("n", "<leader>q", "<cmd>q<CR>", { desc = "Close window" })

local function telescope(action)
    return function()
        require("telescope.builtin")[action]()
    end
end

vim.keymap.set("n", "<leader>ff", telescope("find_files"), { desc = "Find files" })
vim.keymap.set("n", "<leader>fg", telescope("live_grep"), { desc = "Live grep" })
vim.keymap.set("n", "<leader>fb", telescope("buffers"), { desc = "Find buffers" })
vim.keymap.set("n", "<leader>fo", telescope("oldfiles"), { desc = "Find old files" })
vim.keymap.set("n", "<leader>fh", telescope("help_tags"), { desc = "Help tags" })
vim.keymap.set("n", "<leader>gf", telescope("git_files"), { desc = "Git files" })
vim.keymap.set("n", "<leader>gc", telescope("git_commits"), { desc = "Git commits" })
