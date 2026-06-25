# Switching Report

**Date:** Thu Jun 25 14:24:54 2026  

**Config:** `{
  benchmark = "engine_switching",
  switch_cycles = 100
}`  

**Results:** 33 data points  

**Duration:** 124.7s  


## Cross engine

### Individual Runs

| Run | attach_ms | attached | grand_rss_mb | lsp_rss_mb | nvim_rss_mb |
|-----|--------|--------|--------|--------|--------|
| typescript-tools | 187.00 | true | 292.00 | 267.00 | 25.00 |

## Engine switching

### Individual Runs

| Run | avg_ms | cycles | max_ms | median_ms | min_ms | p95_ms |
|-----|--------|--------|--------|--------|--------|--------|
| theme_switching | 1.71 | 100.00 | 6.00 | 1.00 | 1.00 | 3.00 |
| file_open_close | 318.58 | 50.00 | 343.00 | 318.00 | 316.00 | 323.00 |

## Lifecycle after file cycles

### Individual Runs

| Run | attached_bufs | autocmds | child_processes | clients | cpu | gc_kb | grand_rss_kb | lsp_rss_kb | modules | nvim_rss_kb | pid |
|-----|--------|--------|--------|--------|--------|--------|--------|--------|--------|--------|--------|
| ts_ls | 0.00 | — | — | — | — | — | — | — | — | — | 0.00 |
| summary | — | 495.00 | 4.00 | 1.00 | 1.80 | 14052.00 | 442972.00 | 406732.00 | 404.00 | 36240.00 | — |

## Lifecycle after load cleanup

### Individual Runs

| Run | autocmds | child_processes | clients | cpu | gc_kb | grand_rss_kb | lsp_rss_kb | modules | nvim_rss_kb |
|-----|--------|--------|--------|--------|--------|--------|--------|--------|--------|
| summary | 301.00 | 1.00 | 0.00 | 2.40 | 21094.00 | 65860.00 | 0.00 | 404.00 | 65860.00 |

## Lifecycle after load test

### Individual Runs

| Run | attached_bufs | autocmds | child_processes | clients | cpu | gc_kb | grand_rss_kb | lsp_rss_kb | modules | nvim_rss_kb | pid |
|-----|--------|--------|--------|--------|--------|--------|--------|--------|--------|--------|--------|
| ts_ls | 2.00 | — | — | — | — | — | — | — | — | — | 0.00 |
| summary | — | 304.00 | 4.00 | 1.00 | 2.40 | 20922.00 | 658444.00 | 592584.00 | 404.00 | 65860.00 | — |

## Lifecycle after restart cleanup

### Individual Runs

| Run | autocmds | child_processes | clients | cpu | gc_kb | grand_rss_kb | lsp_rss_kb | modules | nvim_rss_kb |
|-----|--------|--------|--------|--------|--------|--------|--------|--------|--------|
| summary | 295.00 | 1.00 | 0.00 | 3.70 | 11860.00 | 29012.00 | 0.00 | 403.00 | 29012.00 |

## Lifecycle after stop

### Individual Runs

| Run | autocmds | child_processes | clients | cpu | gc_kb | grand_rss_kb | lsp_rss_kb | modules | nvim_rss_kb |
|-----|--------|--------|--------|--------|--------|--------|--------|--------|--------|
| summary | 295.00 | 1.00 | 0.00 | 6.10 | 11172.00 | 28756.00 | 0.00 | 403.00 | 28756.00 |

## Lifecycle after theme switching

### Individual Runs

| Run | autocmds | child_processes | clients | cpu | gc_kb | grand_rss_kb | lsp_rss_kb | modules | nvim_rss_kb |
|-----|--------|--------|--------|--------|--------|--------|--------|--------|--------|
| summary | 272.00 | 1.00 | 0.00 | 50.00 | 8888.00 | 26580.00 | 0.00 | 291.00 | 26580.00 |

## Lifecycle attach

### Individual Runs

| Run | attach_ms | attached | cpu | grand_rss_mb | lsp_rss_mb | nvim_rss_mb | total_startup_ms |
|-----|--------|--------|--------|--------|--------|--------|--------|
| ts_ls | 543.00 | true | 9.50 | 365.00 | 337.00 | 27.00 | 2549.00 |

## Lifecycle before file cycles

### Individual Runs

| Run | attached_bufs | autocmds | child_processes | clients | cpu | gc_kb | grand_rss_kb | lsp_rss_kb | modules | nvim_rss_kb | pid |
|-----|--------|--------|--------|--------|--------|--------|--------|--------|--------|--------|--------|
| ts_ls | 2.00 | — | — | — | — | — | — | — | — | — | 0.00 |
| summary | — | 298.00 | 4.00 | 1.00 | 0.70 | 16381.00 | 381536.00 | 347172.00 | 403.00 | 34364.00 | — |

## Lifecycle before load test

### Individual Runs

| Run | autocmds | child_processes | clients | cpu | gc_kb | grand_rss_kb | lsp_rss_kb | modules | nvim_rss_kb |
|-----|--------|--------|--------|--------|--------|--------|--------|--------|--------|
| summary | 495.00 | 1.00 | 0.00 | 1.80 | 14290.00 | 36240.00 | 0.00 | 404.00 | 36240.00 |

## Lifecycle before lsp attach

### Individual Runs

| Run | autocmds | child_processes | clients | cpu | gc_kb | grand_rss_kb | lsp_rss_kb | modules | nvim_rss_kb |
|-----|--------|--------|--------|--------|--------|--------|--------|--------|--------|
| summary | 272.00 | 1.00 | 0.00 | 40.60 | 8994.00 | 26708.00 | 0.00 | 291.00 | 26708.00 |

## Lifecycle before theme switching

### Individual Runs

| Run | autocmds | child_processes | clients | cpu | gc_kb | grand_rss_kb | lsp_rss_kb | modules | nvim_rss_kb |
|-----|--------|--------|--------|--------|--------|--------|--------|--------|--------|
| summary | 272.00 | 1.00 | 0.00 | 25.00 | 6043.00 | 20692.00 | 0.00 | 266.00 | 20692.00 |

## Lifecycle cycling

### Individual Runs

| Run | avg_ms | cycles | max_ms | median_ms | min_ms | p95_ms |
|-----|--------|--------|--------|--------|--------|--------|
| ts_ls | 511.20 | 15.00 | 515.00 | 511.00 | 510.00 | 515.00 |

## Lifecycle cycling growth

### Individual Runs

| Run | cycles | lsp_growth_kb | lsp_growth_per_cycle_kb | nvim_growth_kb | nvim_growth_per_cycle_kb |
|-----|--------|--------|--------|--------|--------|
| ts_ls | 15.00 | -200.00 | -14.00 | 4608.00 | 307.00 |

## Lifecycle load test

### Individual Runs

| Run | autocmds | avg_ms | count | cpu | grand_rss_mb | lsp_rss_mb | max_ms | nvim_rss_mb | total_ms |
|-----|--------|--------|--------|--------|--------|--------|--------|--------|--------|
| 50_files_bulk_open | 703.00 | 9.62 | — | 2.40 | 497.00 | 441.00 | 13.00 | 56.00 | 3543.00 |
| 50_completion_burst | — | 0.02 | — | 2.40 | 642.00 | 578.00 | 1.00 | 64.00 | — |
| diagnostics_count | — | — | 154.00 | — | — | — | — | — | — |

## Lifecycle memory

### Individual Runs

| Run | cpu | final_gc_kb | final_rss_kb | grand_rss_mb | growth_kb | growth_percent | initial_gc_kb | initial_rss_kb | lsp_rss_mb | nvim_rss_mb | samples |
|-----|--------|--------|--------|--------|--------|--------|--------|--------|--------|--------|--------|
| ts_ls/after_ops | 8.90 | — | — | 374.00 | — | — | — | — | 346.00 | 27.00 | — |
| growth_analysis | — | 6939.36 | 63380.00 | — | 0.00 | 0.00 | 6940.76 | 63380.00 | — | — | 5.00 |

## Lifecycle orphans

### Individual Runs

| Run | orphans | total_children | zombie_count |
|-----|--------|--------|--------|
| final_detection | 0.00 | 1.00 | 0.00 |

## Lifecycle restart

### Individual Runs

| Run | attach_ms |
|-----|--------|
| ts_ls | 511.00 |

## Lifecycle stop

### Individual Runs

| Run | stop_ms |
|-----|--------|
| ts_ls | 1505.00 |

## Lsp operations

### Individual Runs

| Run | count | ms |
|-----|--------|--------|
| ts_ls/completion | 1075.00 | 69.00 |
| ts_ls/hover | — | 1.00 |
| ts_ls/definition | — | 1.00 |
| ts_ls/references | 0.00 | 2.00 |
| ts_ls/rename | — | 1.00 |
| ts_ls/formatting | — | 8.00 |

---
_Generated by bench/scripts/result_manager.lua at Thu Jun 25 14:24:54 2026_