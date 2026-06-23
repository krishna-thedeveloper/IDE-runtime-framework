# LSP Memory Benchmark Log

## Methodology
All tests run with `nvim --headless -u <script>`.
Memory measured via `ps` (RSS in KB) for Neovim + all LSP server processes.
Each scenario opens specific file types and waits for LSP clients to attach before measuring.

### Test Scenarios (per configuration)
1. **Baseline (--clean)**: `nvim --clean --headless` — no config, no plugins
2. **Config Loaded**: Config loaded, no files opened, no LSP servers started
3. **lua_ls only**: Open test.lua, wait for lua_ls
4. **ts_ls only**: Open test.ts, wait for ts_ls
5. **jsonls only**: Open test.json, wait for jsonls
6. **yamlls only**: Open test.yaml, wait for yamlls
7. **All 4**: Open all 4 files, wait for all 4 servers

---

## Test 1: Baseline — `nvim --clean`
**Date:** 2026-06-22

| Component | RSS (MB) |
|-----------|----------|
| nvim      | 22       |
| **Total** | **22**   |

---

## Test 2: Baseline — Config Loaded (current `dev` branch, before any fixes)
**Date:** 2026-06-22

| Component       | RSS (MB) |
|-----------------|----------|
| nvim            | 33       |
| **Total**       | **33**   |

---

## Test 3: Baseline — All 4 LSPs (current `dev` branch, before Option A)
**Date:** 2026-06-22

| Process                | RSS (MB) |
|------------------------|----------|
| nvim                   | 33       |
| lua-language-server    | 14       |
| typescript-language-server | 65   |
| tsserver (syntax)      | 170      |
| tsserver (semantic)    | 173      |
| typingsInstaller       | 80       |
| vscode-json-languageserver | 67   |
| yaml-language-server   | 90       |
| **LSP total**          | **659**  |
| **Grand total**        | **692**  |

> Note: ts_ls alone = 65 + 170 + 173 + 80 = **488 MB**

---

## Test 4: Option A — ts_ls with `maxTsServerMemory=2048` + `useSyntaxServer="never"`
**Date:** 2026-06-23

| Process                        | RSS (MB) |
|--------------------------------|----------|
| nvim                           | 25       |
| lua-language-server            | 12       |
| typescript-language-server     | 60       |
| tsserver.js (single)           | 181      |
| typingsInstaller.js            | 78       |
| vscode-json-language-server    | 65       |
| yaml-language-server           | 88       |
| **LSP total**                  | **487**  |
| **Grand total**                | **512**  |

**Savings vs baseline:** 180 MB total (692 → 512 MB), ts_ls alone: 488 → 319 MB (169 MB saved)
**Method:** `useSyntaxServer="never"` removes the separate syntax tsserver fork (~170 MB)

---

## Test 5: Option B — typescript-tools.nvim (with `separate_diagnostic_server=false`)
**Date:** 2026-06-23

| Process                        | RSS (MB) |
|--------------------------------|----------|
| nvim                           | 26       |
| lua-language-server            | 13       |
| typescript-tools tsserver      | 140      |
| typescript-tools typingsInstaller | 74    |
| vscode-json-language-server    | 65       |
| yaml-language-server           | 88       |
| **LSP total**                  | **382**  |
| **Grand total**                | **409**  |

**Savings vs baseline:** 283 MB total (692 → 409 MB)
**Savings vs Option A:** 103 MB (512 → 409 MB)
**Method:** typescript-tools.nvim communicates directly with tsserver, dropping the typescript-language-server wrapper process (~60 MB). Single server mode via `separate_diagnostic_server=false`.
**Note:** Requires globally installed TypeScript (`npm install -g typescript`) or local project node_modules. mason's `ts_ls` excluded via `automatic_enable = { exclude = { "ts_ls" } }`.

---

## Test 6: Option C — vtsls
**Date:** 2026-06-23

| Process                        | RSS (MB) |
|--------------------------------|----------|
| nvim                           | 25       |
| lua-language-server            | 13       |
| vtsls (tsserver partialSemantic) | 144   |
| vtsls (tsserver semantic)      | 156      |
| vtsls (typingsInstaller)       | 87       |
| vscode-json-language-server    | 65       |
| yaml-language-server           | 87       |
| **LSP total**                  | **555**  |
| **Grand total**                | **581**  |

**Savings vs baseline:** 111 MB total (692 → 581 MB)
**Savings vs Option A:** —69 MB (worse than Option A by 69 MB)
**Method:** vtsls replaces typescript-language-server wrapper with direct tsserver integration, saving ~65 MB wrapper process. However, it spawns 2 tsservers by default (partialSemantic + semantic, VSCode defaults) with no single-server option.
**Note:** vtsls applies `--max-old-space-size=3072` (3 GB heap limit) by default.

---

## Test 7: Validation — language_engines generic refactor

### Date: 2026-06-23

### Setup
- Commit `6094bbb` — refactored from TypeScript-specific `config.typescript` to generic `managers.language_engine`
- Persisted engine selection in `~/.config/nvim/language_engines.dat`
- `:LanguageEngine` command lists/switches engines generically
- Provider files under `managers/language_engine/providers/`

### 7a. ts_ls (default) — validates refactor produces same results as Option A

| Process                        | RSS (MB) |
|--------------------------------|----------|
| nvim                           | 26       |
| lua-language-server            | 13       |
| typescript-language-server     | 60       |
| tsserver.js (single)           | 180      |
| typingsInstaller.js            | 78       |
| vscode-json-language-server    | 65       |
| yaml-language-server           | 90       |
| **LSP total**                  | **488**  |
| **Grand total**                | **514**  |

**Comparison with Option A (before refactor):**

| Metric          | Option A (old) | language_engines (new) | Delta |
|-----------------|---------------|------------------------|-------|
| ts_ls wrapper   | 60 MB         | 60 MB                  | 0     |
| tsserver        | 181 MB        | 180 MB                 | −1    |
| typingsInstaller| 78 MB         | 78 MB                  | 0     |
| LSP total       | 484 MB        | 488 MB                 | +4    |
| Grand total     | 512 MB        | 514 MB                 | +2    |

✅ **Validation PASS**: All values within normal measurement variance (1–4 MB). Refactor is transparent.

---

### 7b. typescript-tools — validates switching mechanism (INITIAL — flawed timing)

**Initial measurement** (5-second settle after client attach) showed inflated values due to tsserver pre-GC state.

| Process                        | RSS (MB) |
|--------------------------------|----------|
| nvim                           | 26       |
| lua-language-server            | 13       |
| typescript-tools tsserver      | 166      |
| typescript-tools typingsInstaller | 78    |
| vscode-json-language-server    | 65       |
| yaml-language-server           | 88       |
| **LSP total**                  | **411**  |
| **Grand total**                | **437**  |

### 7c. typescript-tools — SETTLED measurement (25-second settle)

**Key finding:** tsserver RSS drops from 166 MB → 140 MB ~18 seconds after attach, when V8 GC runs.

| Process                        | RSS (MB) |
|--------------------------------|----------|
| nvim                           | 26       |
| lua-language-server            | 13       |
| typescript-tools tsserver      | **140**  |
| typescript-tools typingsInstaller | **74** |
| vscode-json-language-server    | 67       |
| yaml-language-server           | 88       |
| **LSP total**                  | **383**  |
| **Grand total**                | **409**  |

**Comparison with Option B (before refactor):**

| Metric             | Option B (old) | language_engines (settled) | Delta |
|--------------------|---------------|---------------------------|-------|
| tsserver           | 140 MB        | 140 MB                    | **0** |
| typingsInstaller   | 74 MB         | 74 MB                     | **0** |
| LSP total          | 382 MB        | 383 MB                    | +1    |
| Grand total        | 409 MB        | 409 MB                    | **0** |

✅ **Switching validation PASS — zero overhead.** The generic refactor produces identical memory to the old TypeScript-specific implementation. All values match within ±1 MB (measurement rounding).

**Root cause of apparent 26 MB difference:** tsserver (Node.js V8) allocates ~166 MB on startup, then GC reduces it to ~140 MB after ~18 seconds. The initial benchmarks used a 5-second settle, catching pre-GC state. With a 25-second settle, results match perfectly.

✅ **Switching validation**: `:LanguageEngine typescript typescript_tools` correctly:
1. Writes `typescript typescript_tools` to `language_engines.dat`
2. Disables ts_ls `ensure_installed` in mason
3. Enables the typescript-tools.nvim plugin
4. Starts tsserver directly (no typescript-language-server wrapper)
5. LSP client reports name `typescript-tools`

➡ **Recommendation:** All future benchmarks should use ≥25-second settle time after tsserver attach to capture post-GC RSS.

---

## Summary

| Config          | TypeScript (MB) | LSP total (MB) | Grand total (MB) | Savings vs baseline | Savings vs Option A |
|-----------------|-----------------|----------------|------------------|---------------------|---------------------|
| Baseline (clean)| 0               | 0              | 22               | —                   | —                   |
| Baseline (dev)  | 488             | 659            | 692              | —                   | —                   |
| **Option A**    | **319**         | **484**        | **510**          | **182 MB (26%)**    | —                   |
| **Option B**    | **214**         | **382**        | **409**          | **283 MB (41%)**    | **101 MB (20%)**    |
| **Option C**    | **387**         | **555**        | **581**          | **111 MB (16%)**    | **−71 MB (−14%)**   |

## Conclusion

### Winner: Option B — typescript-tools.nvim

```
Memory usage for TypeScript tooling (smallest → largest):
  Option B (typescript-tools):  214 MB  ← BEST (1 tsserver + 1 typingsInstaller)
  Option A (ts_ls + single):    319 MB  ← GOOD (1 wrapper + 1 tsserver + 1 typingsInstaller)
  Option C (vtsls):             387 MB  (2 tsservers + 1 typingsInstaller, no single-server mode)
  Baseline (ts_ls default):     488 MB  (1 wrapper + 2 tsservers + 1 typingsInstaller)
```

**Option B (typescript-tools.nvim)** is the clear winner:
- **101 MB less** than Option A
- Drops the typescript-language-server wrapper process (saves ~60 MB)
- Single server mode with `separate_diagnostic_server = false`
- Uses tsserver directly (same protocol as VSCode)
- Requires globally installed TypeScript or local node_modules

**Option A (ts_ls + single-server)** is the pragmatic choice:
- **182 MB savings** over baseline with zero plugin changes
- Uses existing mason-installed `ts_ls` — no extra dependencies
- Simple config change (`useSyntaxServer="never"`)
- Best choice if you want to keep things simple

**Option C (vtsls)** is not recommended:
- VSCode-compatible but no single-server mode
- Actually more memory than Option A
- Still better than baseline, but worse than both other options

### Recommendation

| Use Case | Choice | Rationale |
|----------|--------|-----------|
| Maximum memory savings | **Option B** | Save 283 MB total, 101 MB more than Option A |
| Simplicity (no new plugins) | **Option A** | Single config change, drops 170 MB syntax server |
| VSCode compatibility | **Option B** | Same tsserver protocol as VSCode |
| Works out-of-the-box | **Option A** | Uses existing mason setup, no global npm install needed |

