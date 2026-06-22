local M = {}

M._listeners = {}

function M.on(event, callback)
  M._listeners[event] = M._listeners[event] or {}
  table.insert(M._listeners[event], callback)
end

function M.off(event, callback)
  if not M._listeners[event] then
    return
  end
  for i, cb in ipairs(M._listeners[event]) do
    if cb == callback then
      table.remove(M._listeners[event], i)
      return
    end
  end
end

function M.emit(event, data)
  if M._listeners[event] then
    for _, cb in ipairs(M._listeners[event]) do
      pcall(cb, data)
    end
  end
end

return M
