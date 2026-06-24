--- Comprehensive benchmark library
local M = { bench_dir = vim.fn.getcwd() .. "/bench" }

--=============================================================================
-- TIMING
--=============================================================================
function M.hrtime() return vim.uv.hrtime() end
function M.elapsed_ms(ns) return math.floor((vim.uv.hrtime() - ns) / 1e6) end
function M.elapsed_us(ns) return (vim.uv.hrtime() - ns) / 1e3 end
function M.now() return vim.uv.now() end

--=============================================================================
-- MEMORY
--=============================================================================
function M.nvim_rss_kb()
  return math.floor((vim.uv or vim.loop).resident_set_memory() / 1024)
end

function M.nvim_vsz_kb()
  local f = io.popen("ps -o vsz= -p " .. vim.fn.getpid() .. " 2>/dev/null")
  if not f then return 0 end
  local vsz = tonumber(f:read("*l"))
  f:close()
  return vsz or 0
end

function M.ps_rss(pid)
  local f = io.popen("ps -o rss= -p " .. pid .. " 2>/dev/null")
  if not f then return 0 end
  local rss = tonumber(f:read("*l"))
  f:close()
  return (rss or 0) * 1024
end

function M.ps_vsz(pid)
  local f = io.popen("ps -o vsz= -p " .. pid .. " 2>/dev/null")
  if not f then return 0 end
  local vsz = tonumber(f:read("*l"))
  f:close()
  return (vsz or 0) * 1024
end

function M.ps_pss(pid)
  local f = io.popen("grep Pss /proc/" .. pid .. "/smaps_rollup 2>/dev/null")
  if not f then return nil end
  local line = f:read("*l")
  f:close()
  if line then
    local pss = tonumber(line:match("(%d+)"))
    return pss and pss * 1024 or nil
  end
  return nil
end

function M.process_tree()
  local nvim_pid = vim.fn.getpid()
  local children = {}
  local f = io.popen("ps --ppid " .. nvim_pid .. " -o pid=,rss=,vsz=,comm= 2>/dev/null")
  if f then
    for line in f:lines() do
      local pid, rss, vsz, comm = line:match("^%s*(%d+)%s+(%d+)%s+(%d+)%s+(.+)$")
      if pid then
        table.insert(children, { pid=tonumber(pid), rss=tonumber(rss)*1024, vsz=tonumber(vsz)*1024, comm=comm })
      end
    end
    f:close()
  end
  -- grandchildren too
  local all = {}
  local function scan(ppid, depth)
    local f2 = io.popen("ps --ppid " .. ppid .. " -o pid=,rss=,vsz=,comm= 2>/dev/null")
    if f2 then
      for line in f2:lines() do
        local pid, rss, vsz, comm = line:match("^%s*(%d+)%s+(%d+)%s+(%d+)%s+(.+)$")
        if pid then
          local entry = { pid=tonumber(pid), ppid=ppid, rss=tonumber(rss)*1024, vsz=tonumber(vsz)*1024, comm=comm, depth=depth }
          table.insert(all, entry)
          scan(tonumber(pid), depth + 1)
        end
      end
      f2:close()
    end
  end
  for _, c in ipairs(children) do
    table.insert(all, { pid=c.pid, ppid=nvim_pid, rss=c.rss, vsz=c.vsz, comm=c.comm, depth=1 })
    scan(c.pid, 2)
  end
  return all
end

function M.lsp_processes()
  local names = {
    "lua-language-server",
    "typescript-language-server",
    "tsserver",
    "typingsInstaller",
    "vscode-json-language-server",
    "yaml-language-server",
  }
  local seen = {}
  local procs = {}
  local total_rss = 0
  -- Also collect via nvim's lsp clients for more accuracy
  local client_pids = {}
  for _, c in ipairs(vim.lsp.get_clients() or {}) do
    if c.rpc and type(c.rpc) == "table" and c.rpc.pid then
      client_pids[c.rpc.pid] = c.name
    end
  end
  for _, name in ipairs(names) do
    local f = io.popen("pgrep -f '" .. name .. "' 2>/dev/null")
    if f then
      for pid_line in f:lines() do
        local pid = tonumber(pid_line:match("^(%d+)"))
        if pid and not seen[pid] then
          seen[pid] = true
          local rss_kb = 0
          local vsz_kb = 0
          local ps_f = io.popen("ps -o rss=,vsz= -p " .. pid .. " 2>/dev/null")
          if ps_f then
            local line = ps_f:read("*l")
            ps_f:close()
            if line then
              local rss_str, vsz_str = line:match("^(%d+)%s+(%d+)")
              rss_kb = tonumber(rss_str) or 0
              vsz_kb = tonumber(vsz_str) or 0
            end
          end
          local pss = M.ps_pss(pid)
          local cmd_f = io.popen("ps -o args= -p " .. pid .. " 2>/dev/null")
          local cmd = "unknown"
          if cmd_f then cmd = cmd_f:read("*l") or "unknown"; cmd_f:close() end
          cmd = cmd:gsub("/home/krish/.-mason/packages/", "mason/")
          cmd = cmd:gsub("/home/krish/.-nvm/versions/node/v%d+%.%d+%.%d+/", "nvm/")
          local client_name = client_pids[pid]
          table.insert(procs, {
            pid=pid, rss=rss_kb*1024, rss_mb=math.floor(rss_kb/1024),
            vsz=vsz_kb*1024, vsz_mb=math.floor(vsz_kb/1024),
            pss=pss, pss_mb=pss and math.floor(pss/1024/1024) or nil,
            cmd=cmd, name=client_name or name,
          })
          total_rss = total_rss + rss_kb * 1024
        end
      end
      f:close()
    end
  end
  return procs, total_rss
end

--=============================================================================
-- CPU
--=============================================================================
function M.cpu_percent(pid)
  local f = io.popen("ps -o %cpu= -p " .. pid .. " 2>/dev/null")
  if not f then return 0 end
  local cpu = tonumber(f:read("*l"))
  f:close()
  return cpu or 0
end

function M.cpu_time(pid)
  local f = io.popen("ps -o cputime= -p " .. pid .. " 2>/dev/null")
  if not f then return 0 end
  local t = f:read("*l")
  f:close()
  -- Parse [[dd-]hh:]mm:ss
  if not t then return 0 end
  local total_sec = 0
  local days, hms = t:match("^(%d+)-(.+)$")
  if days then
    total_sec = total_sec + tonumber(days) * 86400
    t = hms
  end
  local h, m, s = t:match("^(%d+):(%d+):(%d+)$")
  if h then
    total_sec = total_sec + tonumber(h) * 3600 + tonumber(m) * 60 + tonumber(s)
  else
    local ms = t:match("^(%d+):(%d+)$")
    if ms then
      total_sec = total_sec + tonumber(ms) * 60 + tonumber(ms)
    end
  end
  return total_sec
end

function M.all_cpu()
  local procs = M.lsp_processes()
  local total = M.cpu_percent(vim.fn.getpid())
  for _, p in ipairs(procs) do
    total = total + M.cpu_percent(p.pid)
  end
  return total
end

--=============================================================================
-- SNAPSHOT / MEASURE
--=============================================================================
function M.snapshot()
  local nvim_rss = M.nvim_rss_kb() * 1024  -- convert to bytes for consistency
  local procs, lsp_rss = M.lsp_processes()
  local clients = vim.lsp.get_clients()
  local modules = M.count_modules()
  local gc_kb = math.floor(collectgarbage("count"))
  local cpu = M.cpu_percent(vim.fn.getpid())
  return {
    nvim_rss = nvim_rss,
    lsp_procs = procs,
    lsp_rss = lsp_rss,
    clients = clients,
    modules = modules,
    gc_kb = gc_kb,
    cpu = cpu,
    grand_rss = nvim_rss + lsp_rss,
  }
end

function M.measure(label, startup_ns, snap)
  snap = snap or M.snapshot()
  local elapsed = startup_ns and M.elapsed_ms(startup_ns) or 0
  io.write(string.format("\n[%s] elapsed=%dms\n", label, elapsed))
  local nvim_mb = snap.nvim_rss / (1024 * 1024)
  io.write(string.format("nvim: %.0f MB\n", nvim_mb))
  for _, p in ipairs(snap.lsp_procs) do
    local pss_str = p.pss_mb and string.format(" pss=%dMB", p.pss_mb) or ""
    io.write(string.format("  %-5d MB%s vsz=%d MB | %s\n", p.rss_mb, pss_str, p.vsz_mb, p.cmd))
  end
  local lsp_mb = snap.lsp_rss / (1024 * 1024)
  local grand_mb = snap.grand_rss / (1024 * 1024)
  io.write(string.format("lsp_total: %.0f MB | grand_total: %.0f MB\n", lsp_mb, grand_mb))
  io.write(string.format("clients: %d\n", #snap.clients))
  for _, c in ipairs(snap.clients) do
    io.write(string.format("  - %s\n", c.name))
  end
  io.write(string.format("modules: %d | gc_kb: %.0f | cpu: %.1f%%\n", snap.modules, snap.gc_kb, snap.cpu))
  io.write(string.format("timestamp: %s\n", os.date("%Y-%m-%d %H:%M:%S")))
  io.flush()
  return snap
end

--=============================================================================
-- HELPERS
--=============================================================================
function M.wait_for_client(name, timeout_ms)
  return vim.wait(timeout_ms, function()
    for _, c in ipairs(vim.lsp.get_clients()) do
      if c.name == name then return true end
    end
    return false
  end, 200)
end

function M.wait_for_clients(count, timeout_ms)
  return vim.wait(timeout_ms, function()
    return #vim.lsp.get_clients() >= count
  end, 200)
end

function M.count_modules()
  local n = 0
  for k in pairs(package.loaded) do if type(k) == "string" then n = n + 1 end end
  return n
end

function M.trim(s) return s:match("^%s*(.-)%s*$") or s end

--=============================================================================
-- LSP OPERATIONS
--=============================================================================
function M.completion_latency(buf, line, col, label)
  local params = {
    textDocument = vim.lsp.util.make_text_document_params(buf),
    position = { line = line, character = col },
    context = { triggerKind = 1 },
  }
  local start_ns = vim.uv.hrtime()
  local result
  vim.lsp.buf_request(buf, "textDocument/completion", params, function(err, res)
    result = { err = err, res = res }
  end)
  vim.wait(5000, function() return result ~= nil end, 50)
  local elapsed_us = M.elapsed_us(start_ns)
  local elapsed_ms = M.elapsed_ms(start_ns)
  local items = result and result.res and result.res.items and #result.res.items or 0
  io.write(string.format("  completion %s: %.1f ms (%.0f us, items=%d)\n", label, elapsed_ms, elapsed_us, items))
  return elapsed_ms, items
end

function M.hover_latency(buf, line, col, label)
  local params = {
    textDocument = vim.lsp.util.make_text_document_params(buf),
    position = { line = line, character = col },
  }
  local start_ns = vim.uv.hrtime()
  local result
  vim.lsp.buf_request(buf, "textDocument/hover", params, function(err, res)
    result = { err = err, res = res }
  end)
  vim.wait(5000, function() return result ~= nil end, 50)
  local elapsed_us = M.elapsed_us(start_ns)
  local elapsed_ms = M.elapsed_ms(start_ns)
  io.write(string.format("  hover %s: %.1f ms (%.0f us)\n", label, elapsed_ms, elapsed_us))
  return elapsed_ms
end

function M.definition_latency(buf, line, col, label)
  local params = {
    textDocument = vim.lsp.util.make_text_document_params(buf),
    position = { line = line, character = col },
  }
  local start_ns = vim.uv.hrtime()
  local result
  vim.lsp.buf_request(buf, "textDocument/definition", params, function(err, res)
    result = { err = err, res = res }
  end)
  vim.wait(5000, function() return result ~= nil end, 50)
  local elapsed_ms = M.elapsed_ms(start_ns)
  io.write(string.format("  definition %s: %d ms\n", label, elapsed_ms))
  return elapsed_ms
end

function M.reference_latency(buf, line, col, label)
  local params = {
    textDocument = vim.lsp.util.make_text_document_params(buf),
    position = { line = line, character = col },
  }
  local start_ns = vim.uv.hrtime()
  local result
  vim.lsp.buf_request(buf, "textDocument/references", params, function(err, res)
    result = { err = err, res = res }
  end)
  vim.wait(5000, function() return result ~= nil end, 50)
  local elapsed_ms = M.elapsed_ms(start_ns)
  local count = result and result.res and #result.res or 0
  io.write(string.format("  references %s: %d ms (refs=%d)\n", label, elapsed_ms, count))
  return elapsed_ms, count
end

function M.rename_latency(buf, line, col, new_name, label)
  local params = {
    textDocument = vim.lsp.util.make_text_document_params(buf),
    position = { line = line, character = col },
    newName = new_name,
  }
  local start_ns = vim.uv.hrtime()
  local result
  vim.lsp.buf_request(buf, "textDocument/rename", params, function(err, res)
    result = { err = err, res = res }
  end)
  vim.wait(5000, function() return result ~= nil end, 50)
  local elapsed_ms = M.elapsed_ms(start_ns)
  io.write(string.format("  rename %s: %d ms\n", label, elapsed_ms))
  return elapsed_ms
end

--=============================================================================
-- STARTUP TIME PARSER
--=============================================================================
function M.parse_startuptime(filepath)
  local f = io.open(filepath, "r")
  if not f then return {} end
  local entries = {}
  for line in f:lines() do
    local ms, event = line:match("^%s*(%d+%.?%d*)%s+(.+)$")
    if ms then
      table.insert(entries, { ms = tonumber(ms), event = event })
    end
  end
  f:close()
  return entries
end

--=============================================================================
-- EVENTS / AUTOCOMMANDS
--=============================================================================
function M.count_autocmds()
  local total = 0
  local by_event = {}
  for _, augroup in ipairs(vim.fn.getcompletion("", "augroup")) do
    local ok, cmds = pcall(vim.api.nvim_get_autocmds, { group = augroup })
    if ok then
      total = total + #cmds
      for _, cmd in ipairs(cmds) do
        local event = type(cmd.event) == "table" and cmd.event[1] or cmd.event
        by_event[event] = (by_event[event] or 0) + 1
      end
    end
  end
  return total, by_event
end

function M.count_timers()
  -- Attempt to count active handles; fallback to 0 if unsupported
  local ok, handles = pcall(vim.loop, "handles")
  if ok and handles then
    local n = 0
    for _, h in ipairs(handles) do
      if h:is_active() then n = n + 1 end
    end
    return n
  end
  return 0
end

--=============================================================================
-- FORMATTING HELPERS
--=============================================================================
function M.bytes_to_mb(b) return string.format("%.1f", b / 1024 / 1024) end
function M.kb_to_mb(kb) return string.format("%.1f", kb / 1024) end
function M.ms_to_s(ms) return string.format("%.2f", ms / 1000) end

return M
