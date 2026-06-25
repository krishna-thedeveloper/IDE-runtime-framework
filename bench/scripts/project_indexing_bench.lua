local rm = dofile(vim.fn.getcwd() .. "/bench/scripts/result_manager.lua")
local lib = dofile(vim.fn.getcwd() .. "/bench/lib.lua")

local M = {}

local function count_files(dir)
  local f = io.popen("find " .. dir .. " -name '*.ts' -o -name '*.tsx' 2>/dev/null | wc -l")
  local count = tonumber(f:read("*l")) or 0
  f:close()
  return count
end

local function measure_indexing(ctx, proj_path, label)
  local cwd = vim.fn.getcwd()
  vim.fn.chdir(proj_path)

  ctx:log(string.format("\n  Opening project: %s (%s)", label, proj_path))

  local file_count = count_files(proj_path)
  ctx:log(string.format("  Files found: %d", file_count))

  -- Snapshot before
  local snap_before = lib.snapshot()
  local cpu_before = lib.cpu_percent(vim.fn.getpid())

  -- Open all .ts files
  local bufs = {}
  local f = io.popen("find " .. proj_path .. " -name '*.ts' -o -name '*.tsx' | head -2000 2>/dev/null")
  if f then
    for filepath in f:lines() do
      filepath = filepath:gsub("%s+", "")
      if filepath ~= "" then
        local buf = vim.fn.bufadd(filepath)
        vim.fn.bufload(buf)
        vim.bo[buf].filetype = "typescript"
        table.insert(bufs, buf)
      end
    end
    f:close()
  end

  ctx:log(string.format("  Opened %d buffers", #bufs))

  -- Wait for indexing / LSP attach
  local attach_start = lib.hrtime()
  local attached = lib.wait_for_client("ts_ls", 60000)
  local attach_ms = lib.elapsed_ms(attach_start)

  vim.wait(5000)

  -- Snapshot after
  local snap_after = lib.snapshot()
  local cpu_after = lib.cpu_percent(vim.fn.getpid())

  local nvim_delta = math.floor((snap_after.nvim_rss - snap_before.nvim_rss) / 1024 / 1024)
  local lsp_delta = math.floor((snap_after.lsp_rss - snap_before.lsp_rss) / 1024 / 1024)
  local grand_delta = math.floor((snap_after.grand_rss - snap_before.grand_rss) / 1024 / 1024)

  ctx:log(string.format("  Attach time: %dms", attach_ms))
  ctx:log(string.format("  Memory delta: nvim=%dMB lsp=%dMB total=%dMB", nvim_delta, lsp_delta, grand_delta))
  ctx:log(string.format("  CPU: before=%.1f%% after=%.1f%%", cpu_before, cpu_after))

  ctx:record("project_indexing", label, {
    files_opened = #bufs,
    files_found = file_count,
    attach_ms = math.floor(attach_ms),
    nvim_rss_mb = math.floor(snap_after.nvim_rss / 1024 / 1024),
    lsp_rss_mb = math.floor(snap_after.lsp_rss / 1024 / 1024),
    grand_rss_mb = math.floor(snap_after.grand_rss / 1024 / 1024),
    nvim_delta_mb = nvim_delta,
    lsp_delta_mb = lsp_delta,
    grand_delta_mb = grand_delta,
    cpu_before = math.floor(cpu_before * 100) / 100,
    cpu_after = math.floor(cpu_after * 100) / 100,
    modules = snap_after.modules,
    clients = #snap_after.clients,
  })

  -- Cleanup
  for _, c in ipairs(vim.lsp.get_clients()) do
    pcall(c.stop, c)
  end
  vim.cmd("%bdelete!")
  vim.wait(2000)

  vim.fn.chdir(cwd)
end

function M.run(opts)
  opts = opts or {}
  vim.cmd("set noswapfile shortmess+=F")
  local ctx = rm.create_run({ benchmark = "project_indexing" }, "project_indexing")
  ctx:open_log("project_indexing")

  local proj_dir = rm.bench_dir .. "/projects"
  ctx:log("=== Project Indexing Benchmark ===\n")

  local projects = {
    { path = proj_dir .. "/small",  label = "small (10 files)" },
    { path = proj_dir .. "/medium", label = "medium (100 files)" },
    { path = proj_dir .. "/large",  label = "large (1000 files)" },
  }

  for _, proj in ipairs(projects) do
    ctx:log(string.format("--- %s ---", proj.label))
    local ok, err = pcall(measure_indexing, ctx, proj.path, proj.label)
    if not ok then
      ctx:log(string.format("  FAILED: %s", tostring(err)))
      ctx:record("project_indexing", proj.label, {
        error = tostring(err),
      })
    end
    ctx:log("")
  end

  local final = ctx:finalize()
  return final
end

return M
