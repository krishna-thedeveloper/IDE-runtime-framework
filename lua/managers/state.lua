local M = {}

function M.save(name, filepath)
  vim.fn.mkdir(vim.fn.stdpath("state"), "p")
  local f = io.open(filepath, "w")
  if f then
    f:write(name)
    f:close()
  end
end

function M.load(filepath, valid, default)
  local f = io.open(filepath, "r")
  if f then
    local val = f:read("*l")
    f:close()
    val = val and vim.trim(val) or ""
    if val ~= "" and (not valid or valid[val]) then
      return val
    end
  end
  return default
end

return M
