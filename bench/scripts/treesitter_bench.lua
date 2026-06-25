local rm = dofile(vim.fn.getcwd() .. "/bench/scripts/result_manager.lua")
local lib = dofile(vim.fn.getcwd() .. "/bench/lib.lua")

local M = {}

local function generate_large_file(path, lines, line_content)
    line_content = line_content
        or "export const x: number = 42; const fn = (a: string, b: number): boolean => { return a.length > b; };"
    local fh = io.open(path, "w")
    fh:write([=[
import { Component, OnInit } from '@angular/core';
import { FormBuilder, FormGroup, Validators } from '@angular/forms';
import { Observable, of, Subject } from 'rxjs';
import { debounceTime, distinctUntilChanged, switchMap } from 'rxjs/operators';

interface User {
  id: number;
  name: string;
  email: string;
  role: 'admin' | 'user' | 'guest';
  metadata: Record<string, unknown>;
}

type DeepPartial<T> = {
  [P in keyof T]?: T[P] extends object ? DeepPartial<T[P]> : T[P];
};
]=])
    for i = 1, lines do
        fh:write(
            string.format(
                "export const item_%d: User = { id: %d, name: 'user_%d', email: 'user%d@test.com', role: 'user', metadata: { key: 'value_%d' } };\n",
                i,
                i,
                i,
                i,
                i
            )
        )
    end
    fh:write([=[
function processUsers(users: User[]): DeepPartial<User>[] {
  return users.map(u => ({
    id: u.id,
    name: u.name.toUpperCase(),
  }));
}

export class UserService implements OnInit {
  private users: User[] = [];
  private subject = new Subject<string>();

  constructor(private fb: FormBuilder) {}

  ngOnInit() {
    this.subject.pipe(
      debounceTime(300),
      distinctUntilChanged(),
      switchMap(term => this.search(term))
    ).subscribe();
  }

  async search(term: string): Promise<User[]> {
    return this.users.filter(u => u.name.includes(term));
  }

  createForm(): FormGroup {
    return this.fb.group({
      name: ['', Validators.required],
      email: ['', [Validators.required, Validators.email]],
      role: ['user', Validators.required],
    });
  }
}
]=])
    fh:close()
end

function M.run(opts)
    opts = opts or {}
    local ctx = rm.create_run({ benchmark = "treesitter" }, "treesitter")
    ctx:open_log("treesitter")

    local tmp_dir = rm.bench_dir .. "/tmp_ts_bench"
    os.execute("mkdir -p " .. tmp_dir)

    ctx:log("=== Treesitter Benchmark ===\n")

    local file_sizes = {
        { lines = 100, label = "100_lines" },
        { lines = 1000, label = "1k_lines" },
        { lines = 10000, label = "10k_lines" },
    }

    for _, spec in ipairs(file_sizes) do
        ctx:log(string.format("--- %s ---", spec.label))
        local filepath = tmp_dir .. "/" .. spec.label .. ".ts"
        generate_large_file(filepath, spec.lines)

        -- File open time (first load is the measured one)
        local open_times = {}
        local buf
        for i = 1, 3 do
            vim.cmd("%bdelete!")
            collectgarbage("collect")
            local s = lib.hrtime()
            last_buf = vim.fn.bufadd(filepath)
            vim.fn.bufload(last_buf)
            vim.bo[last_buf].filetype = "typescript"
            table.insert(open_times, lib.elapsed_ms(s))
        end
        buf = last_buf
        local open_stats = rm.stats(open_times)
        ctx:log(string.format("  open: avg=%.1fms median=%dms", open_stats.avg or 0, open_stats.median or 0))

        -- Parse time
        local parse_times = {}
        for i = 1, 5 do
            local s = lib.hrtime()
            local ok, parser = pcall(vim.treesitter.get_parser, buf, "typescript")
            if ok and parser then
                parser:parse()
                table.insert(parse_times, lib.elapsed_ms(s))
            end
        end
        local parse_stats = rm.stats(parse_times)
        if parse_stats.avg then
            ctx:log(
                string.format(
                    "  parse: avg=%.1fms median=%dms p95=%dms",
                    parse_stats.avg,
                    parse_stats.median,
                    parse_stats.p95
                )
            )
        else
            ctx:log("  parse: N/A")
        end

        -- Highlight time
        local highlight_times = {}
        for i = 1, 5 do
            local s = lib.hrtime()
            local ok
            if vim.treesitter.highlighter then
                ok = pcall(function()
                    vim.treesitter.highlighter.new(buf)
                end)
            else
                ok = pcall(vim.treesitter.highlight, buf)
            end
            if ok then
                table.insert(highlight_times, lib.elapsed_ms(s))
            end
        end
        local hl_stats = rm.stats(highlight_times)
        if hl_stats.avg then
            ctx:log(string.format("  highlight: avg=%.1fms median=%dms", hl_stats.avg, hl_stats.median))
        else
            ctx:log("  highlight: N/A")
        end

        -- Memory after load
        local snap = lib.snapshot()
        local nvim_mb = math.floor(snap.nvim_rss / 1024 / 1024)
        ctx:log(string.format("  memory: nvim=%dMB gc=%.0fKB", nvim_mb, snap.gc_kb))

        -- CPU during parse
        local cpu = lib.cpu_percent(vim.fn.getpid())

        ctx:record("treesitter_file_open", spec.label, {
            avg_ms = open_stats.avg and math.floor(open_stats.avg * 100) / 100 or 0,
            median_ms = open_stats.median and math.floor(open_stats.median) or 0,
            min_ms = open_stats.min and math.floor(open_stats.min) or 0,
            max_ms = open_stats.max and math.floor(open_stats.max) or 0,
        })

        ctx:record("treesitter_parse", spec.label, {
            avg_ms = parse_stats.avg and math.floor(parse_stats.avg * 100) / 100 or 0,
            median_ms = parse_stats.median and math.floor(parse_stats.median) or 0,
            p95_ms = parse_stats.p95 and math.floor(parse_stats.p95) or 0,
            min_ms = parse_stats.min and math.floor(parse_stats.min) or 0,
            max_ms = parse_stats.max and math.floor(parse_stats.max) or 0,
            stddev_ms = parse_stats.stddev and math.floor(parse_stats.stddev * 100) / 100 or 0,
        })

        ctx:record("treesitter_highlight", spec.label, {
            avg_ms = hl_stats.avg and math.floor(hl_stats.avg * 100) / 100 or 0,
            median_ms = hl_stats.median and math.floor(hl_stats.median) or 0,
            min_ms = hl_stats.min and math.floor(hl_stats.min) or 0,
            max_ms = hl_stats.max and math.floor(hl_stats.max) or 0,
        })

        ctx:record("treesitter_memory", spec.label, {
            nvim_rss_mb = nvim_mb,
            gc_kb = math.floor(snap.gc_kb),
            lines = spec.lines,
        })

        ctx:record("treesitter_cpu", spec.label, {
            cpu = math.floor(cpu * 100) / 100,
        })

        vim.cmd("%bdelete!")
    end

    os.execute("rm -rf " .. tmp_dir)

    local final = ctx:finalize()
    return final
end

return M
