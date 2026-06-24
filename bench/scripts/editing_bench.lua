local rm = dofile(vim.fn.getcwd() .. "/bench/scripts/result_manager.lua")
local lib = dofile(vim.fn.getcwd() .. "/bench/lib.lua")

local M = {}

local function generate_edit_file(path, lines)
  local fh = io.open(path, "w")
  fh:write("// Editing benchmark file\n")
  for i = 1, lines do
    fh:write(string.format("export const line_%d: string = 'content_%d';\n", i, i))
  end
  fh:close()
end

function M.run(opts)
  opts = opts or {}
  local ctx = rm.create_run({ benchmark = "editing" })
  ctx:open_log("editing")

  local tmp_dir = rm.bench_dir .. "/tmp_edit_bench"
  os.execute("mkdir -p " .. tmp_dir)

  ctx:log("=== Editing Workflow Benchmark ===\n")

  local file_sizes = {
    { lines = 100,   label = "100_lines" },
    { lines = 1000,  label = "1k_lines" },
  }

  for _, spec in ipairs(file_sizes) do
    local filepath = tmp_dir .. "/" .. spec.label .. ".ts"
    generate_edit_file(filepath, spec.lines)

    vim.cmd("%bdelete!")
    local buf = vim.fn.bufadd(filepath)
    vim.fn.bufload(buf)
    vim.bo[buf].filetype = "typescript"
    vim.wait(500)

    ctx:log(string.format("--- %s (buffer=%d) ---", spec.label, buf))

    -- Measure single insert latency
    local insert_times = {}
    for i = 1, 100 do
      local s = lib.hrtime()
      pcall(vim.api.nvim_buf_set_text, buf, 0, 0, 0, 0, { "// inserted line\n" })
      table.insert(insert_times, lib.elapsed_ms(s))
    end
    local insert_stats = rm.stats(insert_times)

    -- Undo all inserts
    pcall(vim.cmd, "silent! normal! " .. #insert_times .. "u")

    -- Measure single delete latency
    local delete_times = {}
    for i = 1, 100 do
      local s = lib.hrtime()
      pcall(vim.api.nvim_buf_set_text, buf, spec.lines - 1, 0, spec.lines - 1, 100, { "" })
      table.insert(delete_times, lib.elapsed_ms(s))
    end
    local delete_stats = rm.stats(delete_times)

    -- Measure cursor movement latency
    local move_times = {}
    for i = 1, 100 do
      local line = (i * 10) % math.max(spec.lines, 1)
      local col = (i * 5) % 40
      local s = lib.hrtime()
      pcall(vim.api.nvim_win_set_cursor, 0, { line + 1, col })
      table.insert(move_times, lib.elapsed_ms(s))
    end
    local move_stats = rm.stats(move_times)

    -- Measure visual selection latency
    local visual_times = {}
    for i = 1, 50 do
      local start_line = (i * 5) % math.max(spec.lines - 5, 1)
      local end_line = start_line + math.min(10, spec.lines - start_line - 1)
      local s = lib.hrtime()
      pcall(vim.api.nvim_buf_set_text, buf, start_line, 0, end_line, 0, {})
      table.insert(visual_times, lib.elapsed_ms(s))
      -- Undo
      pcall(vim.cmd, "silent! normal! u")
    end
    local visual_stats = rm.stats(visual_times)

    -- Memory and CPU during edits
    local snap = lib.snapshot()
    local cpu = lib.cpu_percent(vim.fn.getpid())

    ctx:log(string.format("  insert: avg=%.3fms median=%.3fms p95=%.3fms", insert_stats.avg, insert_stats.median, insert_stats.p95))
    ctx:log(string.format("  delete: avg=%.3fms median=%.3fms p95=%.3fms", delete_stats.avg, delete_stats.median, delete_stats.p95))
    ctx:log(string.format("  cursor move: avg=%.3fms median=%.3fms p95=%.3fms", move_stats.avg, move_stats.median, move_stats.p95))
    ctx:log(string.format("  visual select/delete: avg=%.3fms median=%.3fms", visual_stats.avg, visual_stats.median))
    ctx:log(string.format("  memory: nvim=%dMB cpu=%.1f%%", math.floor(snap.nvim_rss / 1024 / 1024), cpu))

    ctx:record("editing_insert", spec.label, {
      samples = 100,
      avg_ms = math.floor(insert_stats.avg * 1000) / 1000,
      median_ms = math.floor(insert_stats.median * 1000) / 1000,
      p95_ms = math.floor(insert_stats.p95 * 1000) / 1000,
      min_ms = math.floor(insert_stats.min * 1000) / 1000,
      max_ms = math.floor(insert_stats.max * 1000) / 1000,
    })

    ctx:record("editing_delete", spec.label, {
      samples = 100,
      avg_ms = math.floor(delete_stats.avg * 1000) / 1000,
      median_ms = math.floor(delete_stats.median * 1000) / 1000,
      p95_ms = math.floor(delete_stats.p95 * 1000) / 1000,
      min_ms = math.floor(delete_stats.min * 1000) / 1000,
      max_ms = math.floor(delete_stats.max * 1000) / 1000,
    })

    ctx:record("editing_cursor_move", spec.label, {
      samples = 100,
      avg_ms = math.floor(move_stats.avg * 1000) / 1000,
      median_ms = math.floor(move_stats.median * 1000) / 1000,
      p95_ms = math.floor(move_stats.p95 * 1000) / 1000,
      min_ms = math.floor(move_stats.min * 1000) / 1000,
      max_ms = math.floor(move_stats.max * 1000) / 1000,
    })

    ctx:record("editing_visual", spec.label, {
      samples = 50,
      avg_ms = math.floor(visual_stats.avg * 1000) / 1000,
      median_ms = math.floor(visual_stats.median * 1000) / 1000,
      min_ms = math.floor(visual_stats.min * 1000) / 1000,
      max_ms = math.floor(visual_stats.max * 1000) / 1000,
    })

    ctx:record("editing_memory", spec.label, {
      nvim_rss_mb = math.floor(snap.nvim_rss / 1024 / 1024),
      gc_kb = math.floor(snap.gc_kb),
      cpu = math.floor(cpu * 100) / 100,
    })

    vim.cmd("%bdelete!")
  end

  os.execute("rm -rf " .. tmp_dir)

  local final = ctx:finalize()
  return final
end

return M
