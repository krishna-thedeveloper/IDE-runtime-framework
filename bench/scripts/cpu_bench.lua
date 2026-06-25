local rm = dofile(vim.fn.getcwd() .. "/bench/scripts/result_manager.lua")
local lib = dofile(vim.fn.getcwd() .. "/bench/lib.lua")

local M = {}

function M.run(opts)
  opts = opts or {}
  local ctx = rm.create_run({ benchmark = "cpu_profiling" }, "cpu")
  ctx:open_log("cpu_profiling")

  local proj_dir = rm.bench_dir .. "/projects"
  ctx:log("=== CPU Profiling Benchmark ===\n")

  local function measure_cpu(label, fn)
    collectgarbage("collect")
    local cpu_before = lib.cpu_percent(vim.fn.getpid())
    local lsp_procs_before, lsp_cpu_before = 0, 0
    for _, p in ipairs(lib.lsp_processes()) do
      local c = lib.cpu_percent(p.pid)
      lsp_cpu_before = lsp_cpu_before + c
      lsp_procs_before = lsp_procs_before + 1
    end
    local total_cpu_before = cpu_before + lsp_cpu_before

    local start_ns = lib.hrtime()
    fn()
    local elapsed_ms = lib.elapsed_ms(start_ns)

    local cpu_after = lib.cpu_percent(vim.fn.getpid())
    local lsp_cpu_after = 0
    for _, p in ipairs(lib.lsp_processes()) do
      local c = lib.cpu_percent(p.pid)
      lsp_cpu_after = lsp_cpu_after + c
    end
    local total_cpu_after = cpu_after + lsp_cpu_after

    ctx:record("cpu_profiling", label, {
      nvim_cpu = math.floor(cpu_after * 100) / 100,
      lsp_cpu = math.floor(lsp_cpu_after * 100) / 100,
      total_cpu = math.floor(total_cpu_after * 100) / 100,
      cpu_delta = math.floor((total_cpu_after - total_cpu_before) * 100) / 100,
      elapsed_ms = math.floor(elapsed_ms),
    })

    ctx:log(string.format("  %s: cpu=%.1f%% lsp_cpu=%.1f%% total=%.1f%% delta=%+.1f%% elapsed=%dms",
      label, cpu_after, lsp_cpu_after, total_cpu_after, total_cpu_after - total_cpu_before, elapsed_ms))
  end

  ctx:log("--- CPU at idle ---")
  measure_cpu("idle", function()
    vim.wait(1000)
  end)

  ctx:log("\n--- CPU during buffer open ---")
  measure_cpu("buffer_open", function()
    vim.cmd("%bdelete!")
    local buf = vim.fn.bufadd(proj_dir .. "/large/src/file_0001.ts")
    vim.fn.bufload(buf)
    vim.bo[buf].filetype = "typescript"
    vim.wait(3000)
  end)

  ctx:log("\n--- CPU during LSP attach ---")
  local ts_buf = vim.fn.bufadd(proj_dir .. "/large/src/file_0100.ts")
  vim.fn.bufload(ts_buf)
  vim.bo[ts_buf].filetype = "typescript"
  local cwd = vim.fn.getcwd()
  vim.fn.chdir(proj_dir .. "/large")
  vim.wait(15000)
  local attached = lib.wait_for_client("ts_ls", 45000)
  vim.fn.chdir(cwd)

  if attached then
    ctx:log("  ts_ls attached")
  end

  measure_cpu("completion", function()
    local params = {
      textDocument = vim.lsp.util.make_text_document_params(ts_buf),
      position = { line = 10, character = 5 },
      context = { triggerKind = 1 },
    }
    local done = false
    vim.lsp.buf_request(ts_buf, "textDocument/completion", params, function() done = true end)
    vim.wait(10000, function() return done end, 50)
  end)

  measure_cpu("hover", function()
    local params = {
      textDocument = vim.lsp.util.make_text_document_params(ts_buf),
      position = { line = 10, character = 5 },
    }
    local done = false
    vim.lsp.buf_request(ts_buf, "textDocument/hover", params, function() done = true end)
    vim.wait(5000, function() return done end, 50)
  end)

  measure_cpu("definition", function()
    local params = {
      textDocument = vim.lsp.util.make_text_document_params(ts_buf),
      position = { line = 10, character = 5 },
    }
    local done = false
    vim.lsp.buf_request(ts_buf, "textDocument/definition", params, function() done = true end)
    vim.wait(5000, function() return done end, 50)
  end)

  measure_cpu("references", function()
    local params = {
      textDocument = vim.lsp.util.make_text_document_params(ts_buf),
      position = { line = 10, character = 5 },
    }
    local done = false
    vim.lsp.buf_request(ts_buf, "textDocument/references", params, function() done = true end)
    vim.wait(5000, function() return done end, 50)
  end)

  measure_cpu("rename", function()
    local params = {
      textDocument = vim.lsp.util.make_text_document_params(ts_buf),
      position = { line = 10, character = 5 },
      newName = "new_var_name_bench",
    }
    local done = false
    vim.lsp.buf_request(ts_buf, "textDocument/rename", params, function() done = true end)
    vim.wait(5000, function() return done end, 50)
  end)

  -- CPU during treesitter parse
  measure_cpu("treesitter_parse", function()
    local ok, parser = pcall(vim.treesitter.get_parser, ts_buf, "typescript")
    if ok and parser then
      parser:parse()
    end
  end)

  -- CPU during diagnostics
  measure_cpu("diagnostics", function()
    vim.wait(5000)
  end)

  -- Peak CPU measurement across all operations
  local peak_cpu = 0
  for i = 1, 20 do
    local c = lib.cpu_percent(vim.fn.getpid())
    if c > peak_cpu then peak_cpu = c end
    vim.wait(100)
  end

  local lsp_peak = 0
  for _, p in ipairs(lib.lsp_processes()) do
    local c = lib.cpu_percent(p.pid)
    if c > lsp_peak then lsp_peak = c end
  end

  ctx:record("cpu_peak", "session", {
    nvim_peak_cpu = math.floor(peak_cpu * 100) / 100,
    lsp_peak_cpu = math.floor(lsp_peak * 100) / 100,
    total_peak_cpu = math.floor((peak_cpu + lsp_peak) * 100) / 100,
  })

  ctx:log(string.format("\nPeak CPU: nvim=%.1f%% lsp=%.1f%% total=%.1f%%", peak_cpu, lsp_peak, peak_cpu + lsp_peak))

  local final = ctx:finalize()
  return final
end

return M
