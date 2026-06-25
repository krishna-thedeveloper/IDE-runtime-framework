local rm = dofile(vim.fn.getcwd() .. "/bench/scripts/result_manager.lua")
local lib = dofile(vim.fn.getcwd() .. "/bench/lib.lua")

local M = {}

local function generate_search_project(dir, file_count)
  os.execute("mkdir -p " .. dir)
  for i = 1, math.min(file_count, 10000) do
    local subdir = dir .. "/src"
    os.execute("mkdir -p " .. subdir)
    local fh = io.open(subdir .. "/file_" .. string.format("%05d", i) .. ".ts", "w")
    fh:write(string.format([[
import { Component, OnInit } from '@angular/core';

@Component({
  selector: 'app-component-%d',
  template: '<div>{{ title }}</div>',
})
export class Component_%d implements OnInit {
  title: string = 'Component %d';
  unique_search_term_%d: number = %d;

  ngOnInit(): void {
    console.log(this.title);
  }

  getData(): Promise<string> {
    return Promise.resolve('data_%d');
  }
}
]], i, i, i, i, i, i))
    fh:close()
  end
end

local function find_picker()
  for _, name in ipairs({ "snacks", "telescope", "fzf-lua" }) do
    local ok, mod = pcall(require, name)
    if ok then return name, mod end
  end
  return nil, nil
end

function M.run(opts)
  opts = opts or {}
  local ctx = rm.create_run({ benchmark = "search" }, "search")
  ctx:open_log("search")

  local tmp_dir = rm.bench_dir .. "/tmp_search_bench"
  ctx:log("=== Search/Picker Benchmark ===\n")

  local project_sizes = {
    { count = 100,   label = "100_files" },
    { count = 1000,  label = "1k_files" },
  }

  for _, spec in ipairs(project_sizes) do
    local proj_path = tmp_dir .. "/" .. spec.label
    ctx:log(string.format("--- %s ---", spec.label))

    local gen_start = lib.hrtime()
    generate_search_project(proj_path, spec.count)
    local gen_ms = lib.elapsed_ms(gen_start)
    ctx:log(string.format("  project setup: %dms", gen_ms))

    -- Open all files into buffer list
    local bufs = {}
    local f = io.popen("find " .. proj_path .. " -name '*.ts' 2>/dev/null")
    if f then
      for filepath in f:lines() do
        local buf = vim.fn.bufadd(filepath)
        vim.fn.bufload(buf)
        vim.bo[buf].filetype = "typescript"
        table.insert(bufs, buf)
      end
      f:close()
    end
    ctx:log(string.format("  loaded %d buffers", #bufs))

    -- Measure vim.fn.glob performance (used by pickers)
    local glob_times = {}
    for i = 1, 10 do
      local s = lib.hrtime()
      local files = vim.fn.globpath(proj_path .. "/src", "*.ts", false, true)
      table.insert(glob_times, lib.elapsed_ms(s))
    end
    local glob_stats = rm.stats(glob_times)

    -- Measure string match (grep) performance
    local grep_times = {}
    for i = 1, 5 do
      local s = lib.hrtime()
      local f2 = io.popen("grep -rl 'unique_search_term' " .. proj_path .. " 2>/dev/null")
      if f2 then
        f2:read("*a")
        f2:close()
      end
      table.insert(grep_times, lib.elapsed_ms(s))
    end
    local grep_stats = rm.stats(grep_times)

    -- Check if picker is available
    local picker_name, _ = find_picker()
    local picker_load_ms = nil
    if picker_name then
      local s = lib.hrtime()
      pcall(require, picker_name)
      picker_load_ms = lib.elapsed_ms(s)
      ctx:log(string.format("  picker available: %s (load: %dms)", picker_name, picker_load_ms))
    else
      ctx:log("  no picker available")
    end

    ctx:log(string.format("  glob: avg=%.1fms median=%dms", glob_stats.avg, glob_stats.median))
    ctx:log(string.format("  grep: avg=%.1fms median=%dms", grep_stats.avg, grep_stats.median))

    local snap = lib.snapshot()

    ctx:record("search_glob", spec.label, {
      files = spec.count,
      avg_ms = math.floor(glob_stats.avg * 100) / 100,
      median_ms = math.floor(glob_stats.median),
      p95_ms = math.floor(glob_stats.p95),
      min_ms = math.floor(glob_stats.min),
      max_ms = math.floor(glob_stats.max),
    })

    ctx:record("search_grep", spec.label, {
      files = spec.count,
      avg_ms = math.floor(grep_stats.avg * 100) / 100,
      median_ms = math.floor(grep_stats.median),
      min_ms = math.floor(grep_stats.min),
      max_ms = math.floor(grep_stats.max),
    })

    ctx:record("search_memory", spec.label, {
      files = spec.count,
      nvim_rss_mb = math.floor(snap.nvim_rss / 1024 / 1024),
      gc_kb = math.floor(snap.gc_kb),
      modules = snap.modules,
    })

    if picker_name and picker_load_ms then
      ctx:record("search_picker_load", picker_name, {
        ms = math.floor(picker_load_ms),
        files = spec.count,
      })
    end

    vim.cmd("%bdelete!")
    collectgarbage("collect")
  end

  os.execute("rm -rf " .. tmp_dir)

  local final = ctx:finalize()
  return final
end

return M
