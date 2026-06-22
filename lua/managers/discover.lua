local M = {}

function M.adapters(prefix)
  local ok, files = pcall(vim.fn.readdir, vim.fn.stdpath("config") .. "/lua/" .. prefix:gsub("%.", "/"))
  if not ok or not files then
    return {}
  end
  local results = {}
  for _, file in ipairs(files) do
    local mod = file:match("^(.*)%.lua$")
    if mod and mod ~= "init" then
      local ok_load, adapter = pcall(require, prefix .. "." .. mod)
      if ok_load and adapter then
        results[mod] = adapter
      end
    end
  end
  return results
end

return M
