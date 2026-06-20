local M = {}

local state_dir = vim.fn.stdpath("state")
local state_file = state_dir .. "/focus.txt"
local active = nil

function M.is_active()
    return active == true
end

function M.enter()
    active = true
    require("statusline").set_layout("minimal")
    vim.opt.showtabline = 0
    pcall(function()
        require("ibl").setup({ enabled = false })
    end)
    vim.cmd("redrawstatus!")
    vim.notify("Focus mode on", vim.log.levels.INFO)
    M.save(true)
end

function M.exit()
    active = false
    local ok_density, density = pcall(require, "managers.density")
    if ok_density then
        density.setup()
    else
        require("statusline").set_layout("full")
        vim.opt.showtabline = 2
    end
    vim.cmd("redrawstatus!")
    vim.notify("Focus mode off", vim.log.levels.INFO)
    M.save(false)
end

function M.toggle()
    if active then
        M.exit()
    else
        M.enter()
    end
end

function M.save(state)
    vim.fn.mkdir(state_dir, "p")
    local f = io.open(state_file, "w")
    if f then
        f:write(state and "1" or "0")
        f:close()
    end
end

function M.load_state()
    local f = io.open(state_file, "r")
    if f then
        local val = f:read("*l")
        f:close()
        active = val and vim.trim(val) == "1"
    end
end

function M.setup()
    M.load_state()
    if active then
        require("statusline").set_layout("minimal")
        vim.opt.showtabline = 0
    end
end

vim.keymap.set("n", "<leader>z", M.toggle, { desc = "Toggle focus mode" })

return M
