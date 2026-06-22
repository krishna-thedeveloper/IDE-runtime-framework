local M = {}

function M.save(name, filepath)
  vim.fn.mkdir(vim.fn.stdpath("state"), "p")
  local f = io.open(filepath, "w")
  if not f then
    vim.notify("Failed to write state: " .. filepath, vim.log.levels.WARN)
    return
  end
  f:write(name)
  f:close()
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
