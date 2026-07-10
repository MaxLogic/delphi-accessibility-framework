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

### 8. P2 - Dynamic hint changes can rescan a growing form repeatedly

Location: `src/MaxLogic.Accessibility.Hints.pas:355-400,426-459`

Every relevant control-list notification calls `Refresh`, which walks the whole form. Adding many controls individually can therefore become quadratic.

Recommended change: hook only the added subtree when message data is reliable, or coalesce one deferred refresh per message cycle.

Proof required: adding 1,000 controls performs bounded/coalesced refresh work and every new windowed control receives a hint hook.

### 9. P2 - Supplemental event fanout needs measurement before reduction

Locations:

- `src/MaxLogic.Accessibility.Manager.pas:2152-2173`
- `src/MaxLogic.Accessibility.Manager.pas:2305-2325`

Radio navigation can emit a property change, selection event, focus event, two MSAA events, and a UIA notification for one action. Some duplication may queue extra NVDA processing, but these events were introduced to fix real announcement gaps. Removing any event without live proof risks accessibility regressions.

Recommended change: add event-type and per-action fanout counters, correlate them with NVDA speech, and reduce only combinations proven redundant.

Expected effect: possible reduction in screen-reader queue pressure with controlled semantic risk.

Proof required: NVDA still announces caption and state for mouse, Tab, Space, and arrow-key scenarios after any consolidation.

## Lower-priority opportunities

- Provider construction still scans hidden and inactive controls eagerly. Exposing only the active visible subtree could shrink large tabbed forms, but it requires correct structure-change events and is higher risk than the findings above.
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
