local rm = dofile(vim.fn.getcwd() .. "/bench/scripts/result_manager.lua")
local lib = dofile(vim.fn.getcwd() .. "/bench/lib.lua")

local M = {}
local ENGINES = { "ts_ls", "typescript_tools" }
local LSP_NAMES = { ts_ls = "ts_ls", typescript_tools = "typescript-tools" }

local function run_single_engine_test(engine_key, proj_path, proj_label)
  local lsp_name = LSP_NAMES[engine_key]
  local engines = require("managers.language_engine")

  local dat_path = vim.fn.stdpath("config") .. "/language_engines.dat"
  local dat_backup
  local f = io.open(dat_path, "r")
  if f then dat_backup = f:read("*a"); f:close() end

  local original_engine = "ts_ls"
  if dat_backup then
    local lang, eng = dat_backup:match("^(%S+)%s+(%S+)$")
    if lang and eng then original_engine = eng end
  end

  engines.set("typescript", engine_key)

  local nvim_bin = vim.env.NVIM or "nvim"
  local cwd = vim.fn.getcwd()
  local result_file = "/tmp/ts_bench_" .. engine_key .. "_" .. proj_label .. ".json"
  local measure_script = cwd .. "/bench/scripts/engine_measure.lua"

  local env = string.format("ENGINE_NAME=%s PROJ_PATH=%s PROJ_LABEL=%s OUTPUT_FILE=%s",
    lsp_name, proj_path, proj_label, result_file)
  local cmd = string.format('%s %s --headless -c "luafile %s" -c "qa!"',
    env, nvim_bin, measure_script)
  os.execute(cmd)

  if dat_backup then
    local f2 = io.open(dat_path, "w")
    if f2 then f2:write(dat_backup); f2:close() end
    engines.set("typescript", original_engine)
  end

  local rf = io.open(result_file, "r")
  if not rf then return { engine = engine_key, project = proj_label, attached = false, error = "no output file" } end
  local content = rf:read("*a")
  rf:close()
  os.remove(result_file)

  local ok, data = pcall(vim.json.decode, content)
  if not ok then return { engine = engine_key, project = proj_label, attached = false, error = "json parse error: " .. tostring(data) } end
  return data
end

function M.run(opts)
  opts = opts or {}
  vim.cmd("set noswapfile shortmess+=F")
  local ctx = rm.create_run({ benchmark = "ts_backend_comparison" }, "ts_backend")
  ctx:open_log("ts_backend_comparison")

  local proj_dir = rm.bench_dir .. "/projects"
  ctx:log("=== TypeScript Backend Benchmark: ts_ls vs typescript-tools ===\n")

  local project_sizes = {
    { path = proj_dir .. "/small",  label = "small" },
    { path = proj_dir .. "/medium", label = "medium" },
    { path = proj_dir .. "/large",  label = "large" },
  }

  for _, proj in ipairs(project_sizes) do
    ctx:log(string.format("\n--- Testing: %s project (%s) ---", proj.label, proj.path))

    for _, engine_key in ipairs(ENGINES) do
      local lsp_name = LSP_NAMES[engine_key]
      local prefix = proj.label .. "/" .. lsp_name

      ctx:log(string.format("  Launching subprocess for %s...", engine_key))
      local r = run_single_engine_test(engine_key, proj.path, proj.label)

      if r.attached then
        ctx:log(string.format("  %s: attached (%dms)", lsp_name, r.attach_ms))
        ctx:log(string.format("    memory baseline: nvim=%dMB lsp=%dMB total=%dMB",
          r.memory.baseline.nvim_rss_mb, r.memory.baseline.lsp_rss_mb, r.memory.baseline.grand_rss_mb))
        ctx:log(string.format("    cpu baseline: %.1f%%", r.cpu.baseline))

        for _, op_name in ipairs({ "completion", "hover", "definition", "references", "rename", "formatting" }) do
          local op_data = r.operations[op_name]
          if op_data then
            local count_str = op_data.count and string.format(" (%d items)", op_data.count) or ""
            ctx:log(string.format("    %s: %.1fms%s", op_name, op_data.ms, count_str))
          end
        end

        ctx:log(string.format("    memory after ops: nvim=%dMB lsp=%dMB total=%dMB",
          r.memory.after_ops.nvim_rss_mb, r.memory.after_ops.lsp_rss_mb, r.memory.after_ops.grand_rss_mb))
        ctx:log(string.format("    cpu after ops: %.1f%%", r.cpu.after_ops))

        if r.errors and #r.errors > 0 then
          for _, e in ipairs(r.errors) do ctx:log("    ERROR: " .. e) end
        end

        ctx:record("ts_backend_attach", prefix, { attached = true, ms = r.attach_ms })
        for op_name, op_data in pairs(r.operations) do
          ctx:record("ts_backend_" .. op_name, prefix, { ms = op_data.ms, count = op_data.count })
        end
        ctx:record("ts_backend_memory", prefix .. "/baseline", {
          nvim_rss_mb = r.memory.baseline.nvim_rss_mb,
          lsp_rss_mb = r.memory.baseline.lsp_rss_mb,
          grand_rss_mb = r.memory.baseline.grand_rss_mb,
        })
        ctx:record("ts_backend_memory", prefix .. "/after_ops", {
          nvim_rss_mb = r.memory.after_ops.nvim_rss_mb,
          lsp_rss_mb = r.memory.after_ops.lsp_rss_mb,
          grand_rss_mb = r.memory.after_ops.grand_rss_mb,
        })
        ctx:record("ts_backend_cpu", prefix, {
          baseline = r.cpu.baseline,
          after_ops = r.cpu.after_ops,
        })
        if r.memory.baseline.grand_rss_mb and r.memory.after_ops.grand_rss_mb then
          ctx:record("ts_backend_memory_growth", prefix, {
            growth_mb = r.memory.after_ops.grand_rss_mb - r.memory.baseline.grand_rss_mb,
          })
        end
      else
        ctx:log(string.format("  %s: NOT AVAILABLE%s", lsp_name, r.error and (" (" .. r.error .. ")") or ""))
        ctx:record("ts_backend_attach", prefix, { attached = false })
      end
    end
  end

  return ctx:finalize()
end

return M
