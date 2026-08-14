# Screen-reader latency performance review

Date: 2026-07-10

## Goal

Minimize framework-added latency between a VCL interaction and the UIA/MSAA response or event consumed by a screen reader. The primary target is keyboard, focus, state-change, hover, and `WM_GETOBJECT` work on the VCL main thread. Agent bridge throughput is reviewed separately because it can compete for the same thread, but it is not the screen-reader contract.

This review covers the current dirty worktree. It does not treat the current antivirus-affected wall-clock measurements as a stable benchmark. Structural evidence, call counts, and process-local diagnostic counters are still useful.

## Existing evidence

| Evidence | Result | Interpretation |
| --- | ---: | --- |
| `.agents/runs/provider-hotspots-tree-current-20260709.json` | 28 UIA nodes in 409.31 ms | External UIA traversal is expensive even for a small tree. |
| Same sample | 1,553 provider-boundary ticks across 434 recorded callbacks | The instrumented Delphi callback bodies are not the main contributor to the 409 ms wall time. |
| `.agents/runs/provider-map-bypass-20260709.json` | 104 provider nodes in 5-8 ms process-local in four of five samples; the lowest three wall times were 166-175 ms | The bridge bypass removes most UIA traversal cost, but pipe scheduling and response serialization remain visible. |
| Same sample | 28 external UIA nodes in 1,139 ms helper time / 1,257 ms wall time | Crossing the UIA client/provider boundary repeatedly dominates a full tree walk. |
| `.agents/runs/listbox-uia-timing-current-20260709-continuation.json` | Enabled vs disabled median: key dispatch 5.168/1.999 ms, `FromHandle` 6.670/1.267 ms, current properties 1.336/0.259 ms | The enabled Debug demo was 2.6x to 5.3x slower in this run. Antivirus activity and synchronous diagnostics make these ratios directional, not acceptance numbers. |
| `bin/Win32/Debug/AccessibilityComplexDemo.a11y.log` | 69.4 MiB, 540,772 lines | Diagnostics are unbounded in a repeatedly tested demo. |
| Same log | 418,382 matched hot-path lines: 109,861 ignored `WM_GETOBJECT`, 166,881 handled `WM_GETOBJECT`, 133,898 returned providers, 7,742 hit tests | 77.4% of all log lines came from high-frequency accessibility request paths. |

The practical conclusion is that further micro-optimizing already-small provider callback bodies will not deliver the largest gain. We first need to remove work that blocks the VCL thread, reduce repeated boundary setup, and keep provider trees bounded.

## Implementation status

| Task | Status | Evidence |
| --- | --- | --- |
| T-109 | Complete | Provider-map serialization queries direct-access, geometry, VCL metadata, and child-access interfaces once per node. Runtime tests cover query counts, failed child counts, depth limits, child limits, and detail levels. Debug correctness gates pass; no latency claim is made because Windows Defender was active during the run. |
| T-110 | Complete | Diagnostics use a bounded non-blocking producer queue and one lazy background writer; the demo is opt-in, logs are share-readable and capped, and hot-path traces perform no extra provider reads. Debug tests pass 337/337, Release UIA probes pass 5/5, and shutdown tests pass 6/6. Defender remained active, so timing distributions below are evidence records rather than acceptance claims. |
| T-111 | Complete | All nine real wrappers cache one atomically published export pointer, concurrent first use resolves once, and the System32 module is pinned before publication. Focused tests pass 9/9, the full Debug suite passes 342/342, and the final Release Basic UIA probe passes. |
| T-112 | Complete | Active-form notifications install only `Screen.ActiveCustomForm`; pointer-keyed, form-owned hint observers avoid repeated refreshes and unregister on destruction. Manager passes 91/91, T-112 scaling passes 1/1, Hints passes 24/24, shutdown passes 6/6, and Release Basic/Hint UIA probes pass. The unrelated bridge scaling performance test timed out under Defender, so that gate and all wall-time acceptance remain deferred. |
| T-113 | Complete | Memo/listbox retained providers are bounded by viewport plus focus/selection; pruning uses one item-count read and a direct index bitmap; stale subtrees become unavailable before disconnect callbacks. The final Debug suite passes 362/362 and Release `MemoListStatus` passes. Defender remained active, so wall-time acceptance is deferred. |
| T-114 | Complete | Stable blank regions on forms, panels, and group boxes cache one conservative negative hover resolution. Direct-child identity, bounds, visibility, semantic messages, focus, and geometry guard invalidation; custom virtual providers remain uncached unless they explicitly prove VCL-complete geometry. Manager passes 103/103, the full Debug suite passes 374/374, shutdown passes 8/8, and the Release Basic UIA probe passes. Defender remained active, so wall-time acceptance is deferred. |
| T-115 | Complete | Each installed form/control hook retains one MSAA wrapper, routes `OBJID_CLIENT` without entering the UIA handler, and releases the wrapper before provider disconnect. MSAA passes 18/18, the full Debug suite passes 378/378, shutdown passes 8/8, and the Release Basic UIA probe passes. Defender remained active, so deterministic query-count reduction is accepted and wall-time acceptance is deferred. |
| T-116 | Complete | The built-in pipe transport parses and serializes on its worker while synchronizing only VCL/provider capture and detached response-tree construction. Phase timings and thread IDs are explicit, maps have bounded defaults and caps, AgentBridge passes 32/32, the full Debug suite passes 380/380, shutdown passes 8/8, and the Release Basic UIA probe passes. Defender remained active, so the threading/bounds result is accepted and wall-time acceptance is deferred. |
| T-117 | Complete | An inserting `CM_CONTROLCHANGE` hooks only the added windowed subtree. A 1,020-control test retains 1,021 hooks with one initial full-tree refresh; Hints passes 25/25 in Debug and Release, the full Debug suite passes 381/381, shutdown passes 8/8, and the Release Hints UIA probe passes. Defender remained active, so the bounded-work result is accepted and wall-time acceptance is deferred. |
| T-118 | Complete | Opt-in diagnostics count typed supplemental UIA and MSAA fanout without synchronous I/O. Deterministic tests and live NVDA evidence did not prove any event redundant, so all accessibility events remain. T118 passes 12/12 in Debug and Release, the full Debug suite passes 386/386, lifecycle tests pass 9/9, and the Release Basic UIA probe passes. |
| T-124 | Complete | A real 26-tab, 625-control VCL fixture measured 575 providers in never-visited inactive tab content. Initial construction now creates the 50 tab-header and active-content providers only; first activation materializes current content once, retains identity while controls live, and preserves native HWND focus behavior. |

### T-110 measurement record

Process-local caller work was measured around `TAccessibilityDiagnostics.Log` with the bounded writer paused so no filesystem work could enter the sample. The Win32 Release run used buffered diagnostics and 200 warmed samples.

| Diagnostics state | Samples | Median | p95 | p99 | Maximum | CPU before/after | Antivirus |
| --- | ---: | ---: | ---: | ---: | ---: | --- | --- |
| Buffered | 200 | 0.0003 ms | 0.0004 ms | 0.0017 ms | 0.0075 ms | 7% / 10% | Microsoft Defender active |

External wall time was measured in Win32 Release with demo diagnostics disabled. Each operation used 200 samples in both framework modes.

| Framework | Operation | Median | p95 | p99 | Maximum |
| --- | --- | ---: | ---: | ---: | ---: |
| Enabled | Send `WM_KEYDOWN`/`WM_KEYUP` | 2.050 ms | 12.556 ms | 17.205 ms | 23.780 ms |
| Enabled | `AutomationElement.FromHandle` | 1.814 ms | 11.978 ms | 23.840 ms | 103.811 ms |
| Enabled | Current properties | 0.436 ms | 2.174 ms | 8.327 ms | 18.353 ms |
| Enabled | `FindAll` children | 0.093 ms | 0.209 ms | 1.208 ms | 16.640 ms |
| Enabled | Scan selected child | 0.104 ms | 0.147 ms | 0.197 ms | 18.201 ms |
| Disabled | Send `WM_KEYDOWN`/`WM_KEYUP` | 2.233 ms | 12.481 ms | 15.658 ms | 20.890 ms |
| Disabled | `AutomationElement.FromHandle` | 2.073 ms | 12.735 ms | 14.373 ms | 15.418 ms |
| Disabled | Current properties | 0.400 ms | 2.967 ms | 9.666 ms | 11.905 ms |
| Disabled | `FindAll` children | 0.069 ms | 0.155 ms | 0.315 ms | 2.607 ms |
| Disabled | Scan selected child | 0.052 ms | 0.074 ms | 0.081 ms | 0.085 ms |

The external run recorded 15% CPU before and 23% after, with Microsoft Defender real-time protection active. Its `FromHandle` target surfaced as a UIA Pane with zero children, so these values measure boundary and main-thread wall time but are not semantic listbox acceptance evidence. The 28-node enabled tree sample took 315.670 ms and the 36-node disabled sample took 224.226 ms. All performance claims remain deferred until the machine is idle.

### T-111 measurement record

The process-local benchmark measures a warmed `UiaClientsAreListening` wrapper call in Win32 Release with diagnostics disabled. The baseline resolves the export on every call; the optimized path performs one atomic cached-pointer read.

| Phase | Samples | Resolve count | Median | p95 | p99 | Maximum | CPU before/after | Antivirus |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | --- | --- |
| Uncached baseline | 200 | 201 | 2 ticks / 0.0002 ms | 3 / 0.0003 ms | 3 / 0.0003 ms | 13 / 0.0013 ms | 14% / 18% | Defender active |
| Cached final | 200 | 1 | 0 ticks / 0.0000 ms | 1 / 0.0001 ms | 1 / 0.0001 ms | 79 / 0.0079 ms | 27% / 38% | Defender active |

The current external run uses Win32 Release, diagnostics disabled, and 200 samples per framework mode.

| Framework | Operation | Median | p95 | p99 | Maximum |
| --- | --- | ---: | ---: | ---: | ---: |
| Enabled | Send `WM_KEYDOWN`/`WM_KEYUP` | 1.986 ms | 11.233 ms | 13.797 ms | 19.145 ms |
| Enabled | `AutomationElement.FromHandle` | 1.745 ms | 11.168 ms | 13.209 ms | 67.233 ms |
| Enabled | Current properties | 0.377 ms | 1.373 ms | 11.094 ms | 14.000 ms |
| Enabled | `FindAll` children | 0.091 ms | 0.205 ms | 0.394 ms | 5.122 ms |
| Enabled | Scan selected child | 0.098 ms | 0.147 ms | 0.179 ms | 5.034 ms |
| Disabled | Send `WM_KEYDOWN`/`WM_KEYUP` | 1.697 ms | 9.204 ms | 13.516 ms | 17.721 ms |
| Disabled | `AutomationElement.FromHandle` | 1.649 ms | 10.340 ms | 11.869 ms | 13.282 ms |
| Disabled | Current properties | 0.343 ms | 1.714 ms | 7.906 ms | 9.919 ms |
| Disabled | `FindAll` children | 0.056 ms | 0.122 ms | 0.164 ms | 0.235 ms |
| Disabled | Scan selected child | 0.053 ms | 0.084 ms | 0.096 ms | 0.109 ms |

The external run recorded CPU at 18% before and 23% after with Defender active. The enabled 28-node tree sample took 310.781 ms and the disabled 36-node sample took 202.193 ms. As in T-110, the target HWND surfaced as a UIA Pane with zero children; the distribution is boundary/main-thread evidence, not semantic listbox proof. The deterministic result is the reduction from 201 export resolutions to one; the final process-local maximum also rose under 27%/38% load, so idle-machine wall-time acceptance remains deferred.

### T-112 measurement record

The process-local benchmark uses 100 future inactive forms and one active form. The 200-sample distribution measures the warm, already-installed `OnActiveFormChange` callback; first activation is recorded separately because it includes VCL window display and message processing. Diagnostics were disabled.

| Phase | Samples | Inactive forms touched | Median | p95 | p99 | Maximum | CPU before/after | Antivirus |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | --- | --- |
| Whole-application rescan baseline | 200 | 100 | 235 ticks / 0.0235 ms | 375 / 0.0375 ms | 543 / 0.0543 ms | 3,488 / 0.3488 ms | 34% / 33% | Defender active |
| Active-form-only final | 200 | 0 | 1 tick / 0.0001 ms | 1 / 0.0001 ms | 1 / 0.0001 ms | 54 / 0.0054 ms | 19% / 28% | Defender active |

The final first-activation sample was 3,672,106 ticks / 367.2106 ms under the same contaminated load; there is no comparable pre-change first-activation sample, so no speedup is claimed for that phase.

The final external run uses Win32 Release, diagnostics disabled, and 200 samples per framework mode.

| Framework | Operation | Median | p95 | p99 | Maximum |
| --- | --- | ---: | ---: | ---: | ---: |
| Enabled | Send `WM_KEYDOWN`/`WM_KEYUP` | 3.871 ms | 25.884 ms | 44.665 ms | 56.112 ms |
| Enabled | `AutomationElement.FromHandle` | 3.045 ms | 27.850 ms | 57.804 ms | 109.522 ms |
| Enabled | Current properties | 0.599 ms | 9.620 ms | 17.952 ms | 32.443 ms |
| Enabled | `FindAll` children | 0.082 ms | 0.244 ms | 1.924 ms | 17.310 ms |
| Enabled | Scan selected child | 0.061 ms | 0.132 ms | 0.172 ms | 6.097 ms |
| Disabled | Send `WM_KEYDOWN`/`WM_KEYUP` | 3.004 ms | 24.467 ms | 31.392 ms | 49.300 ms |
| Disabled | `AutomationElement.FromHandle` | 2.631 ms | 27.931 ms | 51.516 ms | 63.587 ms |
| Disabled | Current properties | 0.477 ms | 13.901 ms | 21.456 ms | 48.382 ms |
| Disabled | `FindAll` children | 0.067 ms | 0.161 ms | 1.104 ms | 1.827 ms |
| Disabled | Scan selected child | 0.052 ms | 0.068 ms | 0.076 ms | 0.084 ms |

CPU was 18% before and 29% after with Defender active. The enabled 28-node tree sample took 1,056.168 ms and the disabled 36-node sample took 577.962 ms; the listbox HWND again surfaced as a zero-child UIA Pane. These are contaminated external-boundary records, not semantic listbox or idle-machine acceptance evidence.

### T-113 measurement record

The process-local Win32 Release run used diagnostics disabled. Cache preparation used 100 samples; stable manager-installed selection traversal used 200 samples for each selected-item cardinality. Percentiles use nearest rank.

| Path | Samples | Retained / bulk reads | Median | p95 | p99 | Maximum |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| Memo viewport reconciliation | 100 | 8 retained | 0.1937 ms | 0.6283 ms | 2.4369 ms | 2.5618 ms |
| Listbox viewport reconciliation | 100 | 11 retained | 8.8976 ms | 24.8139 ms | 31.2540 ms | 35.8500 ms |
| Stable sibling traversal, zero selected | 200 | 0 bulk reads | 0.0643 ms | 0.4435 ms | 1.7790 ms | 2.4343 ms |
| Stable sibling traversal, one selected | 200 | 0 bulk reads | 0.0651 ms | 0.4510 ms | 2.5491 ms | 4.2502 ms |
| Stable sibling traversal, 300 selected | 200 | 0 bulk reads | 0.0667 ms | 0.5236 ms | 2.0945 ms | 3.4847 ms |

Ten CPU samples before the process-local run had median/p95/p99/maximum 29/50/50/50%; ten after had 20/29/29/29%. Defender real-time protection was active with a 533.4 MiB working set, so these wall times are evidence records rather than accepted performance bounds. Structural acceptance is deterministic: retained counts are bounded, stable traversal performs zero native selection snapshots, pruning reads `Items.Count` once and passes direct removal flags to the provider core, and lower-half partial pruning passes its 6x ceiling using three samples per size. The old implementation measured 6.89x growth; a later RED issued 259 `LB_GETCOUNT` messages for 256 items. A controlled callback-failure RED also proved that sequential disconnect could leave a later provider live; the two-phase implementation now marks every removed subtree unavailable, attempts every callback, and rethrows the first exception.

External UIA wall time used Win32 Release, diagnostics disabled, and 200 samples per mode at 13% CPU before and 20% after, with Defender active.

| Framework | Operation | Median | p95 | p99 | Maximum |
| --- | --- | ---: | ---: | ---: | ---: |
| Enabled | Send `WM_KEYDOWN`/`WM_KEYUP` | 2.271 ms | 11.117 ms | 13.115 ms | 14.226 ms |
| Enabled | `AutomationElement.FromHandle` | 1.568 ms | 8.341 ms | 13.033 ms | 57.819 ms |
| Enabled | Current properties | 0.363 ms | 1.109 ms | 4.661 ms | 6.560 ms |
| Enabled | `FindAll` children | 0.079 ms | 0.136 ms | 0.200 ms | 12.897 ms |
| Enabled | Scan selected child | 0.081 ms | 0.123 ms | 0.130 ms | 4.072 ms |
| Disabled | Send `WM_KEYDOWN`/`WM_KEYUP` | 2.122 ms | 11.540 ms | 15.740 ms | 21.262 ms |
| Disabled | `AutomationElement.FromHandle` | 1.643 ms | 5.274 ms | 10.602 ms | 11.490 ms |
| Disabled | Current properties | 0.355 ms | 1.232 ms | 1.975 ms | 9.135 ms |
| Disabled | `FindAll` children | 0.058 ms | 0.115 ms | 0.221 ms | 1.943 ms |
| Disabled | Scan selected child | 0.043 ms | 0.063 ms | 0.073 ms | 0.089 ms |

The enabled tree sample returned 28 nodes in 339.166 ms; disabled returned 36 in 198.308 ms. The target listbox HWND surfaced as `ControlType.Pane` with zero children in both modes. These values therefore measure the native HWND/UIA host boundary, not direct virtual-fragment traversal, and no enabled/disabled speed claim is accepted.

### T-114 measurement record

Negative hover caching is deliberately narrower than a generic "same control" memoization. It applies only to `TCustomForm`, `TCustomPanel`, and `TCustomGroupBox` providers that expose `IAccessibilityVclHoverGeometryPartition` and confirm that direct VCL child geometry completely partitions their hover targets. The manager derives a client-coordinate blank region around the miss, snapshots at most 128 direct child identities, bounds, and visibility flags, and validates that snapshot before every cache hit. Control-tree, geometry, semantic, state, and focus messages clear the miss; paint-only invalidation does not. Moving an ancestor is safe because the blank region is client-relative. Providers with virtual or non-VCL hover children remain uncached by default.

The deterministic RED used 100 mouse moves in one blank region and observed 100 listener/resolution attempts. GREEN observes one attempt. Separate regressions cover forms, panels, group boxes, crossing into a named control, direct-child geometry and visibility, ancestor movement, real sibling focus changes, repaint stability, custom virtual children, and passivation with a populated snapshot.

Process-local work used Win32 Release, diagnostics disabled, 20 warmups, and 200 samples per mode and child count. "Resolved" invalidates the miss before the move; "cached" repeats a move inside the validated region. Percentiles use nearest rank.

| Direct children | Path | Samples | Median | p95 | p99 | Maximum |
| ---: | --- | ---: | ---: | ---: | ---: | ---: |
| 0 | Resolved | 200 | 0.0134 ms | 0.0897 ms | 0.3992 ms | 1.0859 ms |
| 0 | Cached | 200 | 0.0070 ms | 0.0455 ms | 0.2263 ms | 1.2125 ms |
| 1 | Resolved | 200 | 0.0139 ms | 0.2991 ms | 1.4017 ms | 4.0670 ms |
| 1 | Cached | 200 | 0.0070 ms | 0.2508 ms | 0.6979 ms | 5.8717 ms |
| 32 | Resolved | 200 | 0.0256 ms | 0.2878 ms | 0.7333 ms | 2.8338 ms |
| 32 | Cached | 200 | 0.0075 ms | 0.1495 ms | 0.4806 ms | 1.4564 ms |
| 128 | Resolved | 200 | 0.0605 ms | 0.1020 ms | 0.3989 ms | 4.9436 ms |
| 128 | Cached | 200 | 0.0089 ms | 0.0441 ms | 0.2795 ms | 1.4178 ms |

CPU was 28% before and 24% after. Microsoft Defender real-time protection was enabled, `MsMpEng` was resident at 597-614 MiB, and the operator reported antivirus activity since approximately 07:00. The deterministic call-count reduction is accepted; wall-time acceptance remains deferred until the machine is idle.

External UIA wall time used the exact Win32 Release demo, diagnostics disabled, 10 warmups, and 200 samples per framework mode.

| Framework | Operation | Samples | Median | p95 | p99 | Maximum |
| --- | --- | ---: | ---: | ---: | ---: | ---: |
| Enabled | Send `WM_KEYDOWN`/`WM_KEYUP` | 200 | 2.589 ms | 13.749 ms | 18.193 ms | 20.750 ms |
| Enabled | `AutomationElement.FromHandle` | 200 | 1.959 ms | 10.446 ms | 13.642 ms | 39.193 ms |
| Enabled | Current properties | 200 | 0.402 ms | 1.030 ms | 2.391 ms | 8.608 ms |
| Enabled | `FindAll` children | 200 | 0.081 ms | 0.154 ms | 0.287 ms | 1.706 ms |
| Enabled | Scan selected child | 200 | 0.074 ms | 0.122 ms | 0.146 ms | 0.173 ms |
| Disabled | Send `WM_KEYDOWN`/`WM_KEYUP` | 200 | 2.195 ms | 12.199 ms | 15.973 ms | 18.694 ms |
| Disabled | `AutomationElement.FromHandle` | 200 | 1.814 ms | 9.254 ms | 13.352 ms | 14.062 ms |
| Disabled | Current properties | 200 | 0.354 ms | 1.458 ms | 8.061 ms | 11.294 ms |
| Disabled | `FindAll` children | 200 | 0.057 ms | 0.113 ms | 0.203 ms | 1.834 ms |
| Disabled | Scan selected child | 200 | 0.043 ms | 0.060 ms | 0.091 ms | 0.172 ms |

External CPU was 14% before and 13% after with Defender active. The enabled tree sample returned 28 nodes in 279.473 ms; disabled returned 36 nodes in 193.463 ms. As in earlier runs, the target listbox HWND surfaced as a zero-child `ControlType.Pane`; this is host-boundary evidence, not virtual-list semantic acceptance. Exact artifacts are `.agents/runs/t114-process-local-exact-release-20260717/summary.json` and `.agents/runs/t114-external-uia-exact-release-defender-20260717.json`.

### T-115 measurement record

The manager now examines the `WM_GETOBJECT` object ID before choosing a handler. `UiaRootObjectId` enters only the UIA path; `OBJID_CLIENT` enters only the MSAA path. Each form/control hook lazily creates one `IAccessible` wrapper and clears it before provider disconnect. Repeated real requests preserve COM identity and accessibility semantics, while a wrapper retained by a client returns the existing unavailable result after uninstall.

Process-local work used Win32 Release, diagnostics disabled, 20 warmups, and 200 samples per path. The baseline calls the compatibility overload, which creates a wrapper and resolves direct access for every request; the final path retains the wrapper between requests.

| Path | Samples | Direct-access queries | Median | p95 | p99 | Maximum |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| Per-request wrapper baseline | 200 | 200 | 0.2011 ms | 0.6112 ms | 2.5580 ms | 2.7725 ms |
| Per-hook cached wrapper | 200 | 0 | 0.1621 ms | 0.8813 ms | 2.3739 ms | 3.1585 ms |

CPU was 28% before and 40% after. Microsoft Defender was active and its working set moved from 626.0 MiB to 633.1 MiB. The median improved and all 200 repeated interface queries disappeared, but p95 and maximum were mixed under load. The deterministic wrapper/query reduction is accepted; no tail-latency or idle-machine speedup claim is made.

External UIA wall time used the exact normal-path Win32 Release demo, diagnostics disabled, 10 warmups, and 200 samples per framework mode.

| Framework | Operation | Samples | Median | p95 | p99 | Maximum |
| --- | --- | ---: | ---: | ---: | ---: | ---: |
| Enabled | Send `WM_KEYDOWN`/`WM_KEYUP` | 200 | 12.491 ms | 32.793 ms | 41.829 ms | 85.920 ms |
| Enabled | `AutomationElement.FromHandle` | 200 | 7.983 ms | 49.249 ms | 68.399 ms | 94.716 ms |
| Enabled | Current properties | 200 | 1.211 ms | 18.477 ms | 23.650 ms | 34.434 ms |
| Enabled | `FindAll` children | 200 | 0.105 ms | 0.270 ms | 1.308 ms | 2.216 ms |
| Enabled | Scan selected child | 200 | 0.076 ms | 0.132 ms | 0.164 ms | 4.718 ms |
| Disabled | Send `WM_KEYDOWN`/`WM_KEYUP` | 200 | 13.327 ms | 35.513 ms | 46.067 ms | 70.307 ms |
| Disabled | `AutomationElement.FromHandle` | 200 | 8.705 ms | 46.434 ms | 75.178 ms | 108.105 ms |
| Disabled | Current properties | 200 | 1.505 ms | 17.961 ms | 34.986 ms | 38.222 ms |
| Disabled | `FindAll` children | 200 | 0.089 ms | 0.188 ms | 1.459 ms | 2.494 ms |
| Disabled | Scan selected child | 200 | 0.054 ms | 0.069 ms | 0.090 ms | 0.106 ms |

External CPU was 34% before and 32% after with Defender active. The enabled tree sample returned 28 nodes in 367.558 ms; disabled returned 36 in 327.600 ms. The target listbox again surfaced as a zero-child `ControlType.Pane`, so this is host-boundary and correctness context rather than semantic listbox or idle performance acceptance. Exact artifacts are `.agents/runs/t115-msaa-getobject-release-exact.json` and `.agents/runs/t115-external-uia-final-release-defender-20260717.json`.

### T-116 measurement record

The built-in pipe transport now parses request JSON on its worker, synchronizes only VCL/provider capture plus construction of an owned detached JSON value tree, and serializes that tree on the worker. `captureBuildElapsedTicks` measures the main-thread capture/build body; `synchronizedElapsedTicks` measures total work inside the synchronized callback and excludes queue wait; `serializationElapsedTicks` measures worker-side response-body serialization. `elapsedTicks` includes parsing, synchronization queue wait, synchronized work, and body serialization, but excludes pipe I/O and final timing-suffix construction. Thread IDs prove capture remains on the VCL thread while parsing and serialization occur on the pipe worker.

Process-local evidence used the exact Win32 Release demo (`SHA-256 86A2F16D81D1D9462D72F4D3D9238E4DC52742B0448B8E2847F90EA12B1DDADC`), diagnostics disabled, 20 warmups, and 200 samples per command.

| Command / phase | Samples | Median | p95 | p99 | Maximum |
| --- | ---: | ---: | ---: | ---: | ---: |
| Full `form.map`, pipe wall | 200 | 107.5129 ms | 185.4831 ms | 204.8084 ms | 225.6807 ms |
| Full `form.map`, synchronized main thread | 200 | 101.9872 ms | 174.5370 ms | 199.1639 ms | 214.4132 ms |
| Full `form.map`, worker serialization | 200 | 0.4448 ms | 0.8231 ms | 0.9964 ms | 1.0224 ms |
| Full `form.map`, estimated old synchronized work | 200 | 102.4217 ms | 175.2816 ms | 199.6256 ms | 214.9052 ms |
| Geometry `form.map`, pipe wall | 200 | 6.1331 ms | 9.3512 ms | 12.4395 ms | 14.9080 ms |
| Geometry `form.map`, synchronized main thread | 200 | 0.6749 ms | 1.0024 ms | 2.3208 ms | 2.7619 ms |
| Geometry `form.map`, worker serialization | 200 | 0.1401 ms | 0.3692 ms | 0.4336 ms | 0.4797 ms |
| Geometry `form.map`, estimated old synchronized work | 200 | 0.8701 ms | 1.2985 ms | 2.5882 ms | 2.8923 ms |
| `provider.map`, pipe wall | 200 | 83.7203 ms | 191.5580 ms | 228.8772 ms | 270.4853 ms |
| `provider.map`, synchronized main thread | 200 | 79.0849 ms | 183.3378 ms | 214.3324 ms | 256.2851 ms |
| `provider.map`, worker serialization | 200 | 0.3985 ms | 0.6868 ms | 0.8177 ms | 1.4164 ms |
| `provider.map`, estimated old synchronized work | 200 | 79.6068 ms | 183.9219 ms | 214.5959 ms | 256.6143 ms |

The geometry path removes about 22% of median and 23% of p95 estimated synchronized work by moving parse/serialization off-thread. Full and provider maps remain dominated by capture/provider construction, so no broader latency claim is made. CPU was 51% before and 45% after; Defender was active at 629.3/632.8 MiB. Those conditions contaminate all wall times.

External UIA wall time used the same exact Release binary, diagnostics disabled, 10 warmups, and 200 samples per framework mode.

| Framework | Operation | Samples | Median | p95 | p99 | Maximum |
| --- | --- | ---: | ---: | ---: | ---: | ---: |
| Enabled | Send `WM_KEYDOWN`/`WM_KEYUP` | 200 | 25.909 ms | 67.327 ms | 116.637 ms | 130.451 ms |
| Enabled | `AutomationElement.FromHandle` | 200 | 43.108 ms | 119.696 ms | 179.650 ms | 193.012 ms |
| Enabled | Current properties | 200 | 6.894 ms | 36.301 ms | 53.068 ms | 79.435 ms |
| Enabled | `FindAll` children | 200 | 0.136 ms | 1.633 ms | 1.969 ms | 2.319 ms |
| Enabled | Scan selected child | 200 | 0.062 ms | 0.102 ms | 0.132 ms | 0.150 ms |
| Disabled | Send `WM_KEYDOWN`/`WM_KEYUP` | 200 | 22.799 ms | 59.328 ms | 98.573 ms | 110.720 ms |
| Disabled | `AutomationElement.FromHandle` | 200 | 33.989 ms | 91.721 ms | 120.726 ms | 167.211 ms |
| Disabled | Current properties | 200 | 5.854 ms | 38.479 ms | 53.467 ms | 61.489 ms |
| Disabled | `FindAll` children | 200 | 0.122 ms | 1.268 ms | 1.806 ms | 2.382 ms |
| Disabled | Scan selected child | 200 | 0.060 ms | 0.084 ms | 0.112 ms | 0.164 ms |

External CPU was 56% before and 43% after with Defender active. The enabled tree returned 28 nodes in 1,567.522 ms and the disabled tree returned 36 nodes in 2,936.894 ms. The target listbox again surfaced as a zero-child `ControlType.Pane`, so this is host-boundary telemetry rather than semantic listbox or idle-machine acceptance. Exact artifacts are `.agents/runs/t116-agent-bridge-exact-final-release-defender-20260717.json` and `.agents/runs/t116-external-uia-exact-final-release-defender-20260717.json`.

## Ranked findings

### 1. P0 - Synchronous diagnostics block accessibility requests

Locations:

- `demos/AccessibilityComplexDemo.dpr:115`
- `src/MaxLogic.Accessibility.Diagnostics.pas:725-749`
- `src/MaxLogic.Accessibility.ProviderCore.pas:1805-1817`
- `src/MaxLogic.Accessibility.ProviderCore.pas:1997-2043`
- `src/MaxLogic.Accessibility.Manager.pas:1830-1852`
- `src/MaxLogic.Accessibility.Manager.pas:2496-2548`

The demo enables file diagnostics unconditionally. Every log line takes a global monitor, checks or creates the directory, formats a timestamp, opens/appends/closes a UTF-8 file through `TFile.AppendAllText`, and does so on the caller thread. `WM_GETOBJECT`, hit testing, and several event paths call it directly from the VCL/UIA request path. Antivirus scanning amplifies the cost of repeated file opens and writes.

Hit-test logging also calls `ProviderHitTestDescription`, so enabling diagnostics changes the property-query workload being measured.

Recommended change:

- Make verbose demo logging opt-in.
- Move directory creation and file setup to `Configure`.
- Use a bounded, non-blocking producer queue and one writer thread when logging is enabled.
- Keep the file open with Windows share-read/share-write access so test agents can inspect it while the demo runs.
- Rotate or truncate per run and report dropped diagnostic records rather than blocking accessibility work when the queue is full.
- Keep hot-path messages as counters or sampled records; do not read extra provider properties merely to describe a trace line.

Expected effect: removes filesystem latency and lock contention from the most frequent UIA/VCL paths. This is the highest-confidence latency win.

Proof required: a regression test must show that `Log` performs no filesystem append on the caller thread, a live reader can open the active file, and a Release enabled/disabled comparison stays within the framework-overhead budget below.

### 2. P0 - UIAutomationCore exports are resolved repeatedly

Location: `src/MaxLogic.Accessibility.UIAutomationCore.pas:431-479,551-624`

The DLL module is cached, but every wrapper call rebuilds an `AnsiString` export name and calls `GetProcAddress`. Focus, selection, notification, and hover sequences can resolve several exports for one user action. This is avoidable boundary setup on the main thread.

Recommended change: cache one function pointer per `TUIAutomationCoreExport` in a fixed array. Use a lock only on cache miss and return the cached pointer on the normal path. Preserve the current System32 loading and shutdown behavior.

Expected effect: converts each wrapper call from string conversion plus export lookup to one indexed pointer read. The isolated gain is expected to be small and must be measured; this finding does not explain the existing hundreds-of-milliseconds tree walks.

Proof required: repeated calls to every real wrapper must resolve each export once, remain thread-safe, and preserve missing-export errors.

### 3. P0 - Every active-form change rescans every live form and hint tree

Locations:

- `src/MaxLogic.Accessibility.Manager.pas:2736-2746`
- `src/MaxLogic.Accessibility.Manager.pas:2882-2936`
- `src/MaxLogic.Accessibility.Manager.pas:2991-3001`
- `src/MaxLogic.Accessibility.Hints.pas:426-459`
- `src/MaxLogic.Accessibility.Hints.pas:745-764`

`ActiveFormChanged` calls `ScanCurrentForms`. Every already-installed form is looked up again, its hint observer is found with a linear list scan, and that observer recursively refreshes the entire form tree. The resulting cost is proportional to all live forms and controls exactly when a new dialog or form receives focus.

This is broader than the documented contract requires. Initial installation should scan existing forms; subsequent active-form events can install only `Screen.ActiveCustomForm`. Forms that never become active already have an explicit `Install(Form)` contract.

Recommended change:

- Install only `Screen.ActiveCustomForm` during `OnActiveFormChange`.
- Index hint observers by form instead of scanning a list.
- Do not refresh an existing form's complete hint tree merely because it became active; dynamic control notifications already exist for changes.

Expected effect: active-form transition cost becomes proportional to the newly active form instead of the entire application.

Proof required: with 100 inactive live forms, an active-form event must touch only the active form and must not refresh unrelated hint observers.

### 4. P0 - Memo and listbox virtual child caches grow with scroll history

Locations:

- `src/MaxLogic.Accessibility.VclAdapters.pas:189-201,246-262`
- `src/MaxLogic.Accessibility.VclAdapters.pas:2770-2803,2844-2925`
- `src/MaxLogic.Accessibility.VclAdapters.pas:3268-3327,3496-3568`
- `src/MaxLogic.Accessibility.ProviderCore.pas:93`

Visible memo lines and listbox items are added to dictionaries and the inherited provider child list. Providers are not evicted when they leave the viewport. The listbox removes entries only when item text becomes empty or a provider is already disconnected; the memo has no normal stale-line removal path.

After scrolling through a large control, UIA navigation cost and memory use become proportional to every index ever visited rather than the current viewport. The grid providers already reconcile stale children and provide a local pattern to follow.

Recommended change: reconcile children to the visible set plus the focused item and any selected items required by the UIA selection contract. Disconnect and remove stale providers so outstanding references return `UIA_E_ELEMENTNOTAVAILABLE` safely. If clients must enumerate or realize arbitrary off-screen items, implement the corresponding UIA virtualization/item-container contract instead of retaining an accidental history of previously visible children.

Expected effect: stable memory and navigation cost independent of scroll history.

Proof required: after visiting disjoint viewports in a 10,000-item list and a 10,000-line memo, retained providers must remain bounded by viewport size plus focus/selection, and preparation cost after 100 scrolls must remain close to the first prepared viewport.

### 5. P1 - Hover misses repeat the full resolution path on every mouse move

Locations:

- `src/MaxLogic.Accessibility.Manager.pas:428-431`
- `src/MaxLogic.Accessibility.Manager.pas:1679-1711`
- `src/MaxLogic.Accessibility.Manager.pas:1821-1878`
- `src/MaxLogic.Accessibility.Manager.pas:2068-2103`
- `src/MaxLogic.Accessibility.Manager.pas:2615-2641`

The hover cache represents only a successful leaf announcement. A miss clears the cache, so repeated `WM_MOUSEMOVE` messages over blank space repeat the listener probe, VCL hit test, provider lookup, and property reads.

Recommended change: cache negative resolution for the current target control and stable region. Invalidate it on control-tree, geometry, focus, or state changes. A move into another control must still resolve immediately.

Expected effect: one resolution per blank region instead of one per mouse message.

Proof required: 100 moves within one blank panel cause one resolution attempt; crossing into a named control still raises the expected hover event immediately.

### 6. P1 - MSAA wrappers are allocated for every `OBJID_CLIENT` request

Locations:

- `src/MaxLogic.Accessibility.Msaa.pas:131-139`
- `src/MaxLogic.Accessibility.Msaa.pas:819-839`
- `src/MaxLogic.Accessibility.Manager.pas:1830-1852,2525-2548`

Each MSAA `WM_GETOBJECT` request creates a `TAccessibilityMsaaProvider` and performs four interface queries. The manager first invokes the UIA handler even for `OBJID_CLIENT`, which also generates the high-volume ignored log entry when diagnostics are enabled.

Recommended change: route by object ID before invoking the unrelated handler and cache the `IAccessible` wrapper for the lifetime of the provider hook. Release it during the existing passivation/disconnect sequence.

Expected effect: no per-request wrapper allocation or repeated `Supports` calls, and no irrelevant UIA-handler work for MSAA requests.

Proof required: repeated `OBJID_CLIENT` requests reuse one wrapper and preserve role, name, state, and shutdown safety.

Implemented by T-115. The deterministic result is zero repeated direct-access interface queries after warmup and one wrapper identity per installed hook; contaminated wall-time distributions are retained above without an acceptance claim.

### 7. P1 - Agent bridge requests monopolize the VCL thread

Locations:

- `src/MaxLogic.Accessibility.AgentBridge.PipeServer.pas:159-175`
- `src/MaxLogic.Accessibility.AgentBridge.pas:1270-1289`
- `src/MaxLogic.Accessibility.AgentBridge.pas:1320-1337`

The pipe thread synchronizes the complete bridge command to the VCL thread. Tree capture, JSON object construction, and JSON serialization all run there. The reported `elapsedMs`/`elapsedTicks` are captured before `JsonObjectToString`, so bridge telemetry excludes part of the main-thread occupancy it is meant to explain.

Recommended change:

- First report capture/build, serialization, and total synchronized occupancy separately.
- Then capture VCL data into detached records on the main thread and serialize those records on the pipe thread.
- Keep all VCL and provider interface access on the VCL thread; only detached data may cross the thread boundary.
- Apply bounded defaults for expensive maps so automation cannot starve assistive technology.

Expected effect: bridge automation can coexist with screen-reader traffic with shorter main-thread stalls.

Proof required: a large map reports honest total time and spends materially less time in the synchronized section without touching VCL objects off-thread.

Implemented by T-116. The pipe worker owns parsing and serialization, the VCL thread owns all capture/provider access, and tests verify thread IDs, timing relationships, response equivalence, and configured map bounds. The exact geometry sample reduced median synchronized work from an estimated 0.8701 ms to 0.6749 ms, but Defender contaminated wall time; structural threading and bounded-work acceptance is complete while idle timing acceptance remains deferred.

### T-117 measurement record

The process-local benchmark times each insertion into an already observed form. It uses Win32 Release with diagnostics disabled, 20 warmups, and 1,000 measured controls. The final form has 1,020 inserted controls, 1,021 hooks including the form, and only the initial full-tree refresh.

| Samples | Median | p95 | p99 | Maximum | CPU before/after | Antivirus |
| ---: | ---: | ---: | ---: | ---: | --- | --- |
| 1,000 | 0.0021 ms | 0.0033 ms | 0.0054 ms | 0.0177 ms | 31% / 38% | Microsoft Defender active, 489.8 / 486.6 MiB |

External UIA wall time used the Win32 Release demo with diagnostics disabled, 10 warmups, and 200 samples per operation in each framework mode.

| Framework | Operation | Median | p95 | p99 | Maximum |
| --- | --- | ---: | ---: | ---: | ---: |
| Enabled | Send `WM_KEYDOWN`/`WM_KEYUP` | 4.810 ms | 22.597 ms | 30.046 ms | 48.613 ms |
| Enabled | `AutomationElement.FromHandle` | 2.967 ms | 13.219 ms | 16.190 ms | 19.896 ms |
| Enabled | Current properties | 0.501 ms | 3.444 ms | 7.989 ms | 20.504 ms |
| Enabled | `FindAll` children | 0.090 ms | 0.190 ms | 2.439 ms | 2.795 ms |
| Enabled | Scan selected child | 0.085 ms | 0.137 ms | 0.189 ms | 11.276 ms |
| Disabled | Send `WM_KEYDOWN`/`WM_KEYUP` | 3.244 ms | 14.485 ms | 22.844 ms | 25.686 ms |
| Disabled | `AutomationElement.FromHandle` | 2.492 ms | 12.344 ms | 23.440 ms | 31.488 ms |
| Disabled | Current properties | 0.405 ms | 1.729 ms | 7.282 ms | 9.534 ms |
| Disabled | `FindAll` children | 0.061 ms | 0.117 ms | 0.168 ms | 1.639 ms |
| Disabled | Scan selected child | 0.051 ms | 0.064 ms | 0.098 ms | 2.641 ms |

External CPU was 27% before and 34% after with Defender active. The enabled and disabled tree samples were 28 nodes in 338.824 ms and 36 nodes in 327.340 ms. The target again surfaced as a zero-child Pane, so this is host-boundary evidence rather than semantic listbox acceptance. Wall-time acceptance remains deferred until the machine is idle.

### 8. P2 - Dynamic hint changes can rescan a growing form repeatedly

Location: `src/MaxLogic.Accessibility.Hints.pas:355-400,426-459`

Every relevant control-list notification calls `Refresh`, which walks the whole form. Adding many controls individually can therefore become quadratic.

Recommended change: hook only the added subtree when message data is reliable, or coalesce one deferred refresh per message cycle.

Proof required: adding 1,000 controls performs bounded/coalesced refresh work and every new windowed control receives a hint hook.

Implemented by T-117. The observer consumes the inserted control from `CM_CONTROLCHANGE` and recursively hooks only that `TWinControl` subtree. Removal no longer causes a full-form refresh; each control-owned hook already handles its own destruction. The exact scaling test proves all 1,020 controls are hooked with one initial full-tree refresh.

### 9. P2 - Supplemental event fanout needs measurement before reduction

Locations:

- `src/MaxLogic.Accessibility.Manager.pas:2152-2173`
- `src/MaxLogic.Accessibility.Manager.pas:2305-2325`

Radio navigation can emit a property change, selection event, focus event, two MSAA events, and a UIA notification for one action. Some duplication may queue extra NVDA processing, but these events were introduced to fix real announcement gaps. Removing any event without live proof risks accessibility regressions.

Recommended change: add event-type and per-action fanout counters, correlate them with NVDA speech, and reduce only combinations proven redundant.

Expected effect: possible reduction in screen-reader queue pressure with controlled semantic risk.

Proof required: NVDA still announces caption and state for mouse, Tab, Space, and arrow-key scenarios after any consolidation.

Implemented by T-118 as measurement-only instrumentation. Provider-hotspot diagnostics now count successful supplemental UIA automation, property, notification, and structure events by type, plus framework MSAA focus, state, selection, and other event attempts. Collection remains opt-in and performs no file I/O.

Deterministic interaction fanout:

| Interaction | UIA automation | UIA property | UIA notification | MSAA |
| --- | --- | --- | --- | --- |
| Checkbox hover | focus 1 | none | none | focus 1, state 1 |
| Checkbox focus | none | none | none | focus 1, state 1 |
| Already-focused checkbox toggle | none | none | none | none; native control owns the state event |
| Group caption hover | focus 1 | none | 1 | none |
| Radio hover or focus | focus 1 | none | 1 | focus 1, state 1 |
| Grouped-radio selection | focus 2, selection 1 | selected 1 | 1 | focus 2, state 3 |
| Grouped-radio or `TRadioGroup` arrow | focus 1, selection 1 | selected 2 | 1 | focus 1, state 2 |

The exact Win32 Release counter benchmark used 100 warmups and 2,000 samples, with five UIA and three MSAA records per sample. With file diagnostics disabled, the disabled counter path measured median/p95/p99/max 0.0000/0.0001/0.0001/0.0001 ms; enabled provider metrics measured 0.0001/0.0002/0.0002/0.0006 ms. CPU was 82% before and 60% after, and Defender was active.

The exact external UIA run used 10 warmups and 200 samples per enabled/disabled mode with diagnostics disabled. Enabled key dispatch measured median/p95/p99/max 4.556/20.818/28.845/33.844 ms and disabled measured 4.131/18.144/21.521/49.913 ms. Enabled `AutomationElement.FromHandle` measured 3.028/17.846/40.890/61.921 ms and disabled measured 2.555/15.108/30.426/36.772 ms. Enabled current-property reads measured 0.563/7.856/11.017/14.775 ms and disabled measured 0.432/3.983/8.167/11.066 ms. The 28-node enabled tree took 666.084 ms and the 36-node disabled tree took 369.887 ms. CPU was 31% before and 41% after with Defender active, so these wall times are contamination evidence, not comparative performance acceptance.

Live NVDA evidence retained captions for both group hovers, radio hover/focus/click/arrow interactions, and checkbox click/Space state changes. It also showed event results being merged and delayed: one view-radio click utterance arrived 29 ms after a 3.8-second capture boundary, and checkbox hover was not spoken in that run despite the expected supplemental event attempts. This does not prove any event redundant. No event combination was removed; the safer behavior remains in place pending cleaner live evidence.

Final exact-candidate gates: Debug passes 386/386 with zero failures, errors, ignores, or leaks; the nine targeted application-run, passivation, late-hook, destroyed-form, idempotent-uninstall, and active-form-handler lifecycle tests pass; FixInsight remains at 405 and Pascal Analyzer at 7,946 total/218 strong warnings with no semantic addition; normal-path Debug and Release demo rebuilds pass DFM validation; and the Release `BasicVclControls` probe reports `UIA_PROBE_OK`. Exact artifacts are `.agents/runs/t118-event-counter-latency-release-exact-final-defender-20260717.json`, `.agents/runs/t118-external-uia-release-exact-final-defender-20260717.json`, and `.agents/runs/t118-live-nvda-fanout-focused-debug-20260717.json`.

### T-124 measurement record

The self-contained Win32 Release fixture constructs a real `TForm` with 26 `TTabSheet` instances and 598 nested accessible controls. Setup and handle creation are outside the timed region. One warmup precedes seven provider-tree construction samples; structural counts are acceptance evidence and wall time is directional.

| Phase | Constructed active | Constructed inactive | Total | Median | p95 / maximum |
| --- | ---: | ---: | ---: | ---: | ---: |
| Eager baseline | 50 | 575 | 625 | 20,454 ticks / 2.0454 ms | Not recorded |
| Deferred final | 50 | 0 | 50 | 8,853 ticks / 0.8853 ms | 9,761 ticks / 0.9761 ms |

Initial provider count fell by 92%. The observed median fell by 56.7%, but the structural reduction is the accepted result because the baseline and final were separate local runs. Correctness tests cover first activation, exactly-once structure invalidation, runtime additions, live captions, destruction/disconnection, reparent identity, path-only destination materialization, fragment navigation, hit testing, tab selection, and native HWND focus ownership.

The lifecycle is deliberately one-way per tab: never-visited inactive descendants are deferred; after first activation, constructed providers remain stable until their VCL controls are destroyed. Moving a constructed control into an unvisited tab creates only the missing ancestor path. Runtime controls added to an unvisited tab remain deferred until activation.

## Lower-priority opportunities

- Provider construction still scans control metadata eagerly, but provider objects for never-visited inactive tab descendants are now deferred by T-124. Broader deferral for arbitrary hidden containers remains intentionally out of scope until measured against a real semantic need.
- Adapter resolution and label association repeat some class walks and linear searches during installation. These are startup costs, not the current interaction hot path; measure them before adding caches.
- Avoid further string/allocation micro-optimization until the blocking and algorithmic findings are resolved. Existing diagnostics show the provider callback bodies are already small relative to external UIA traversal.

## Proposed acceptance budgets

These are initial engineering budgets to validate on an otherwise idle machine in Win32 Release. They are framework-overhead targets, not guarantees for NVDA speech synthesis or Windows cross-process scheduling.

- No synchronous filesystem operation on any UIA callback, `WM_GETOBJECT`, focus, selection, state-change, or hover path.
- Enabled-minus-disabled key-dispatch overhead: median at most 1 ms, p95 at most 3 ms over at least 200 warmed iterations.
- Repeated current-property query overhead: median at most 1 ms, p95 at most 3 ms over at least 200 warmed iterations.
- Active-form change work is independent of unrelated live form count.
- Memo/listbox retained virtual providers are bounded by the active viewport plus required focus/selection providers.
- Performance runs report median, p95, p99, maximum, sample count, build configuration, diagnostics mode, and antivirus/system-load status.
- Debug builds remain the correctness target; Release builds with diagnostics disabled or buffered are the performance acceptance target.

## Recommended order

1. Remove synchronous diagnostics I/O and establish a clean Release baseline.
2. Cache UIAutomationCore function pointers.
3. Limit active-form work to the active form and stop unconditional hint refreshes.
4. Bound memo/listbox virtual providers.
5. Cache negative hover results and reuse MSAA wrappers.
6. Separate bridge capture from serialization and measure main-thread occupancy honestly.
7. Coalesce dynamic hint refresh and investigate event fanout only with live NVDA evidence.

The first clean benchmark should be delayed until antivirus activity has settled. Reusing the current contaminated wall-clock numbers as a regression threshold would encode machine load rather than framework cost.
