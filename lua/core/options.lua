vim.opt.number = true
vim.opt.relativenumber = true

vim.opt.expandtab = true
vim.opt.shiftwidth = 4
vim.opt.tabstop = 4

vim.opt.wrap = false

vim.opt.ignorecase = true
vim.opt.smartcase = true

vim.opt.cursorline = true

vim.opt.splitbelow = true
vim.opt.splitright = true

vim.opt.scrolloff = 8

vim.opt.termguicolors = true

vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

vim.opt.foldmethod = "expr"
vim.opt.foldexpr = "v:lua.vim.treesitter.foldexpr()"
vim.opt.foldlevel = 99
