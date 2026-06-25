--- LSP Benchmark Suite
--- Measures attach time, init, diagnostics, completions across all LSP servers
--- Usage: nvim --headless -c "lua require('bench.scripts.lsp_bench').run()" -c "qa!"

local rm = dofile(vim.fn.getcwd() .. "/bench/scripts/result_manager.lua")
local lib = dofile(vim.fn.getcwd() .. "/bench/lib.lua")

local M = {}

local LSP_SERVERS = { "ts_ls", "lua_ls", "jsonls", "yamlls" }

function M.run(opts)
  opts = opts or {}
  local ctx = rm.create_run({ benchmark = "lsp", servers = LSP_SERVERS }, "lsp")
  ctx:open_log("lsp")

  local proj_dir = rm.bench_dir .. "/projects"
  ctx:log("=== LSP Benchmark ===")
  ctx:log("")

  local t0 = lib.hrtime()

  -- Helper: measure LSP operation latency with multiple samples
  local function measure_lsp_op(buf, method, params, label, samples)
    samples = samples or 5
    local latencies = {}
    local results_data = {}

    for i = 1, samples do
      local start_ns = vim.uv.hrtime()
      local result
      vim.lsp.buf_request(buf, method, params, function(err, res)
        result = { err = err, res = res }
      end)
      vim.wait(10000, function() return result ~= nil end, 100)
      local ms = lib.elapsed_ms(start_ns)
      table.insert(latencies, ms)
      if result and result.res then
        table.insert(results_data, result.res)
      end
    end

    local stats = rm.stats(latencies)
    ctx:record("lsp_operation", label, {
      method = method,
      avg_ms = stats.avg,
      median_ms = stats.median,
      min_ms = stats.min,
      max_ms = stats.max,
      p95_ms = stats.p95,
      p99_ms = stats.p99,
      stddev_ms = stats.stddev,
      samples = samples,
    })
    ctx:log(string.format("  %s: avg=%.1fms median=%.0fms p95=%.0fms (n=%d)",
      label, stats.avg, stats.median, stats.p95, samples))
    return stats, results_data
  end

  --- 1. TypeScript LSP (ts_ls)
  ctx:log("--- 1. TypeScript LSP ---")
  local ts_proj = proj_dir .. "/large"
  local ts_file = ts_proj .. "/src/file_0500.ts"
  local orig_dir = vim.fn.getcwd()
  ctx:log(string.format("  Chdir to %s", ts_proj))
  vim.fn.chdir(ts_proj)
  ctx:log(string.format("  Opening %s ...", ts_file))
  vim.cmd("e " .. ts_file)
  vim.bo.filetype = "typescript"

  local attach_start = lib.hrtime()
  local ts_attached = lib.wait_for_client("ts_ls", 45000)
  local attach_ms = lib.elapsed_ms(attach_start)
  ctx:record("lsp_attach", "ts_ls", { ms = attach_ms, attached = tostring(ts_attached) })
  ctx:log(string.format("  ts_ls attach: %d ms (ok=%s)", attach_ms, ts_attached))

  if ts_attached then
    ctx:log("  Waiting 15s for indexing...")
    vim.wait(15000)

    local buf = vim.fn.bufnr("%")

    -- Diagnostics
    ctx:log("  Diagnostics...")
    local diag_start = lib.hrtime()
    vim.wait(5000)
    local diags = vim.diagnostic.get(buf)
    local diag_ms = lib.elapsed_ms(diag_start)
    ctx:record("lsp_diagnostics", "ts_ls", { count = #diags, elapsed_ms = diag_ms })

    -- Completion
    measure_lsp_op(buf, "textDocument/completion", {
      textDocument = vim.lsp.util.make_text_document_params(buf),
      position = { line = 1, character = 5 },
      context = { triggerKind = 1 },
    }, "ts_ls_completion", 5)

    -- Hover
    measure_lsp_op(buf, "textDocument/hover", {
      textDocument = vim.lsp.util.make_text_document_params(buf),
      position = { line = 3, character = 10 },
    }, "ts_ls_hover", 3)

    -- Definition
    measure_lsp_op(buf, "textDocument/definition", {
      textDocument = vim.lsp.util.make_text_document_params(buf),
      position = { line = 3, character = 10 },
    }, "ts_ls_definition", 3)

    -- References
    measure_lsp_op(buf, "textDocument/references", {
      textDocument = vim.lsp.util.make_text_document_params(buf),
      position = { line = 3, character = 10 },
    }, "ts_ls_references", 3)

    -- Rename
    measure_lsp_op(buf, "textDocument/rename", {
      textDocument = vim.lsp.util.make_text_document_params(buf),
      position = { line = 3, character = 10 },
      newName = "DataRenamed",
    }, "ts_ls_rename", 3)

    -- Code action
    measure_lsp_op(buf, "textDocument/codeAction", {
      textDocument = vim.lsp.util.make_text_document_params(buf),
      range = { start = { line = 0, character = 0 }, ["end"] = { line = 1, character = 0 } },
      context = { diagnostics = {} },
    }, "ts_ls_code_action", 3)

    -- Document symbols
    measure_lsp_op(buf, "textDocument/documentSymbol", {
      textDocument = vim.lsp.util.make_text_document_params(buf),
    }, "ts_ls_document_symbol", 3)

    -- Formatting
    measure_lsp_op(buf, "textDocument/formatting", {
      textDocument = vim.lsp.util.make_text_document_params(buf),
      options = { tabSize = 2, insertSpaces = true },
    }, "ts_ls_formatting", 3)
  end
  vim.fn.chdir(orig_dir)

  --- 2. LuaLS
  ctx:log("\n--- 2. LuaLS ---")
  local lua_file = rm.bench_dir .. "/lib.lua"
  vim.cmd("%bdelete!")
  vim.cmd("e " .. lua_file)
  vim.bo.filetype = "lua"

  local lua_attach_start = lib.hrtime()
  local lua_attached = lib.wait_for_client("lua_ls", 15000)
  local lua_attach_ms = lib.elapsed_ms(lua_attach_start)
  ctx:record("lsp_attach", "lua_ls", { ms = lua_attach_ms, attached = tostring(lua_attached) })
  ctx:log(string.format("  lua_ls attach: %d ms (ok=%s)", lua_attach_ms, lua_attached))

  if lua_attached then
    vim.wait(5000)
    local lua_buf = vim.fn.bufnr("%")

    measure_lsp_op(lua_buf, "textDocument/completion", {
      textDocument = vim.lsp.util.make_text_document_params(lua_buf),
      position = { line = 1, character = 5 },
      context = { triggerKind = 1 },
    }, "lua_ls_completion", 3)

    measure_lsp_op(lua_buf, "textDocument/hover", {
      textDocument = vim.lsp.util.make_text_document_params(lua_buf),
      position = { line = 1, character = 5 },
    }, "lua_ls_hover", 3)

    measure_lsp_op(lua_buf, "textDocument/definition", {
      textDocument = vim.lsp.util.make_text_document_params(lua_buf),
      position = { line = 1, character = 5 },
    }, "lua_ls_definition", 3)
  end

  --- 3. JSONLS
  ctx:log("\n--- 3. JSONLS ---")
  local json_file = proj_dir .. "/large/tsconfig.json"
  vim.cmd("%bdelete!")
  vim.cmd("e " .. json_file)
  vim.bo.filetype = "json"

  local json_attach_start = lib.hrtime()
  local json_attached = lib.wait_for_client("jsonls", 15000)
  local json_attach_ms = lib.elapsed_ms(json_attach_start)
  ctx:record("lsp_attach", "jsonls", { ms = json_attach_ms, attached = tostring(json_attached) })
  ctx:log(string.format("  jsonls attach: %d ms (ok=%s)", json_attach_ms, json_attached))

  if json_attached then
    vim.wait(3000)
    local json_buf = vim.fn.bufnr("%")

    measure_lsp_op(json_buf, "textDocument/completion", {
      textDocument = vim.lsp.util.make_text_document_params(json_buf),
      position = { line = 1, character = 5 },
      context = { triggerKind = 1 },
    }, "jsonls_completion", 3)

    measure_lsp_op(json_buf, "textDocument/hover", {
      textDocument = vim.lsp.util.make_text_document_params(json_buf),
      position = { line = 1, character = 5 },
    }, "jsonls_hover", 3)
  end

  --- 4. LSP Scaling: project sizes
  ctx:log("\n--- 4. LSP Scaling ---")
  local projects = {
    { name = "small",  path = proj_dir .. "/small",  files = 10 },
    { name = "medium", path = proj_dir .. "/medium", files = 100 },
    { name = "large",  path = proj_dir .. "/large",  files = 1000 },
    { name = "huge",   path = proj_dir .. "/huge",   files = 10000 },
  }

  local orig_dir = vim.fn.getcwd()
  for _, proj in ipairs(projects) do
    ctx:log(string.format("  Project: %s (%d files)", proj.name, proj.files))
    vim.cmd("%bdelete!")
    vim.fn.chdir(proj.path)
    vim.cmd("e " .. proj.path .. "/src/file_0001.ts")
    vim.bo.filetype = "typescript"
    vim.wait(10000)

    local mem_snap = lib.snapshot()
    ctx:record("lsp_scaling", proj.name, {
      files = proj.files,
      nvim_rss_mb = math.floor(mem_snap.nvim_rss / 1024 / 1024),
      lsp_rss_mb = math.floor(mem_snap.lsp_rss / 1024 / 1024),
      grand_rss_mb = math.floor(mem_snap.grand_rss / 1024 / 1024),
      clients = #mem_snap.clients,
      modules = mem_snap.modules,
    })
    ctx:log(string.format("    nvim=%dMB lsp=%dMB total=%dMB clients=%d",
      math.floor(mem_snap.nvim_rss / 1024 / 1024),
      math.floor(mem_snap.lsp_rss / 1024 / 1024),
      math.floor(mem_snap.grand_rss / 1024 / 1024),
      #mem_snap.clients))
  end
  vim.fn.chdir(orig_dir)

  --- 5. Multi-LSP: open all file types simultaneously
  ctx:log("\n--- 5. Multi-LSP Test ---")
  vim.cmd("%bdelete!")
  local multi_files = {
    { path = proj_dir .. "/large/src/file_0001.ts", ft = "typescript" },
    { path = rm.bench_dir .. "/lib.lua", ft = "lua" },
    { path = proj_dir .. "/large/tsconfig.json", ft = "json" },
  }
  for _, mf in ipairs(multi_files) do
    vim.cmd("e " .. mf.path)
    vim.bo.filetype = mf.ft
  end
  vim.wait(15000)

  local multi_snap = lib.snapshot()
  ctx:record("lsp_multi", "all_servers", {
    clients = #multi_snap.clients,
    nvim_rss_mb = math.floor(multi_snap.nvim_rss / 1024 / 1024),
    lsp_rss_mb = math.floor(multi_snap.lsp_rss / 1024 / 1024),
    grand_rss_mb = math.floor(multi_snap.grand_rss / 1024 / 1024),
  })
  ctx:log(string.format("  Multi-LSP: clients=%d nvim=%dMB lsp=%dMB total=%dMB",
    #multi_snap.clients,
    math.floor(multi_snap.nvim_rss / 1024 / 1024),
    math.floor(multi_snap.lsp_rss / 1024 / 1024),
    math.floor(multi_snap.grand_rss / 1024 / 1024)))

  -- Detect duplicate clients
  local client_counts = {}
  for _, c in ipairs(vim.lsp.get_clients()) do
    client_counts[c.name] = (client_counts[c.name] or 0) + 1
  end
  for name, count in pairs(client_counts) do
    if count > 1 then
      ctx:record("lsp_duplicates", name, { count = count })
      ctx:log(string.format("  WARNING: Duplicate %s client (%d instances)", name, count))
    end
  end

  local final = ctx:finalize()
  return final
end

return M
