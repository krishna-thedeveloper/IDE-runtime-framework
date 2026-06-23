local M = {
  provider = "ts_ls",
}

local function load()
  local f = io.open(vim.fn.stdpath("config") .. "/typescript_engine.dat", "r")
  if f then
    M.provider = f:read("*l"):gsub("%s+", "")
    f:close()
  end
end

local function save()
  vim.fn.mkdir(vim.fn.stdpath("config"), "p")
  local f = io.open(vim.fn.stdpath("config") .. "/typescript_engine.dat", "w")
  if f then
    f:write(M.provider)
    f:close()
  end
end

M.load = load
M.save = save

load()

vim.api.nvim_create_user_command("TypescriptEngine", function(opts)
  local valid = { ["ts_ls"] = true, ["typescript-tools"] = true }
  if opts.args and opts.args ~= "" then
    if not valid[opts.args] then
      vim.notify("Invalid engine: " .. opts.args .. ". Valid: ts_ls, typescript-tools", vim.log.levels.ERROR)
      return
    end
    M.provider = opts.args
    save()
    vim.notify("TypeScript engine set to: " .. opts.args .. ". Restart Neovim to apply.", vim.log.levels.INFO)
  else
    vim.notify("Current TypeScript engine: " .. M.provider, vim.log.levels.INFO)
  end
end, { nargs = "?" })

return M
