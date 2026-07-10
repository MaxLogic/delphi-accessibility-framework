# Changelog

## 2026-07-10
### Fixed
- Agent bridge provider maps now query direct-access, geometry, VCL metadata, and child-access interfaces at most once per provider node and reuse those results while serializing the snapshot.
- Provider-map child metadata is now written once per node, and failed child-count calls cannot leak a dirty out value into JSON.

## 2026-07-09
### Added
- Agent bridge `provider.map` can now return a capped in-process framework provider-tree snapshot, including virtual children, without walking external UIA.
- The desktop-control helper now exposes `bridge-provider-map` for fast MaxLogic provider-tree diagnostics.
- The desktop-control helper now exposes `fast-semantic-map`, which tries the MaxLogic provider bridge first for semantic discovery and falls back to cached UIA for generic Windows applications.
- Agent bridge `controls.info` can now enrich several current snapshot refs in one request, sharing one focus read, one RTTI cache, and cached snapshot rectangles for the batch.
- The desktop-control helper now exposes `bridge-controls-info` for batched bridge detail reads after a geometry map.
- Provider hotspot diagnostics now time focus-announcement text construction and UIA notification dispatch separately, making speech-delay investigations distinguish our text work from the UIA/NVDA event boundary.

### Fixed
- VCL adapters now reuse scanner-provided explicit fallback text before doing their own RTTI explicit-text checks, avoiding duplicate adapter RTTI reads for clear captioned custom controls.
- Virtual hover providers now cache leaf bounds through direct in-process geometry access instead of the public UIA bounding-rectangle callback wrapper.
- Agent bridge `provider.map` now reads provider rectangles through direct in-process geometry access instead of the public UIA bounding-rectangle callback wrapper.
- Agent bridge `provider.map` now treats direct-access provider misses as final instead of falling back to public UIA property callbacks, avoiding duplicate provider-boundary work while building in-process semantic maps.
- Agent bridge `provider.map` now reuses the provider tree already installed by `TAccessibilityManager` when available, avoiding a fresh accessibility scan and provider rebuild for managed forms.
- Paired VCL focus messages now reuse the cached focus announcement before rebuilding speech text, avoiding duplicate synchronous text construction on focus transitions.
- Focus and hover speech now remove duplicate leading value text from help text with a single-pass helper instead of repeated delete/trim string work on long hints.
- Focus and hover speech now skips duplicate-removal scan/copy work when there is no value text to remove, returning already-clean help text directly.
- Focus and hover speech now returns already-clean non-duplicate help text directly when value text is present but not duplicated, avoiding a full-string copy on independent hints.
- The desktop-control helper `uia-map` now lists `bridge-provider-map` as a faster alternative, so bridge-enabled VCL apps can route semantic discovery to the in-process provider-tree bypass instead of external UIA traversal.
- The desktop-control helper now reads MaxLogic bridge response lines in one buffered binary read instead of one byte at a time, reducing client overhead for large `form.map` JSON snapshots.
- The desktop-control helper `fast-map` now caps automatic default-pipe bridge probes at 5 ms and clamps retry sleeps to the remaining deadline, so custom-pipe or no-bridge targets fall back to Win32 mapping without a hidden 25-250 ms wait.
- The desktop-control helper `fast-semantic-map` now uses a separate 75 ms automatic bridge probe, giving bridge-enabled apps a fair chance to answer from in-process `provider.map` before falling back to slow external UIA traversal.
- The desktop-control helper `fast-semantic-map --pid` now probes the process-default MaxLogic bridge directly when no title filter is requested, avoiding native top-level window enumeration before the in-process provider-tree bypass.
- The desktop-control helper `fast-semantic-map` now includes bridge `fallbackAttempts` when it has to return a cached UIA map, making slow UIA samples distinguishable from the preferred in-process provider bypass.
- Static provider sibling navigation now reuses the current prepared child snapshot when parent indexes are still valid, avoiding repeated child-preparation work during UIA sibling walks.
- Multi-select `TListBox`/`TCheckListBox` UIA selection queries now fill the selection `SAFEARRAY` directly from selected indexes, avoiding a transient provider-list allocation.
- TMS `TAdvStringGrid` visible-cell refresh now checks active/visible ancestor state once per refresh instead of once per candidate cell.
- `TStringGrid` and TMS `TAdvStringGrid` focus queries now reuse current prepared visible-cell providers instead of refreshing and probing visible cells again when the focused cell is already prepared.
- Common UIA provider properties now use typed fields instead of `OleVariant` fields on the hot provider path, reducing allocation/conversion pressure during provider creation and direct property reads.
- Agent bridge snapshot refs now use direct string construction instead of `Format`, reducing per-control allocation/parser overhead during large `form.map` snapshots.
- Manager, hint, and scanner hook passivation now use per-hook retained flags instead of scanning retained lists, removing quadratic shutdown/passivation work on heavily hooked legacy forms.
- Provider runtime IDs are now copied with one native block copy per destination array instead of per-Integer assignment during provider creation and structure-change events.
- VCL adapter fallback RTTI property lookups are now cached by class/property, reducing repeated `GetPropInfo` work when large legacy forms use many controls of the same custom class.
- Scanner RTTI fallback caching now avoids composite string key construction on cache hits, reducing allocation pressure during full accessibility scans of large legacy forms.
- MSAA focus queries now use direct focused-item providers before generic fragment-root focus traversal, reducing provider work when screen readers ask for current grid/list focus through MSAA.
- MSAA location queries now read provider bounds through direct in-process geometry access instead of the public UIA bounding-rectangle callback wrapper.
- MSAA hit testing now uses direct in-process framework root access before falling back to public UIA root callbacks, including form/body misses that resolve to self.
- Listbox item `SelectionItemPattern` containers now return the owner list provider directly instead of calling the public UIA parent-navigation callback.
- VCL radio-button and tab-sheet `SelectionItemPattern` containers now read the parent provider directly instead of calling the public UIA parent-navigation callback.
- Memo visible-line preparation now clamps candidate lines to the memo's native line count and reuses that known range when creating line providers, avoiding native existence probes for nonexistent lines.
- Memo visible-line preparation now reuses its one native line-count read and skips off-screen caret-line queries, leaving native memo accessibility to own caret speech.
- Agent bridge `hitTest` now reuses screen rectangles from the current `form.map` snapshot, avoiding live `ClientToScreen`/parent-geometry probes for mapped controls during pointer automation.
- Agent bridge `control.info` now reuses screen rectangles from the current `form.map` snapshot, avoiding another live VCL geometry probe when automation enriches one mapped control.
- Fixed-height `TListBox`/`TCheckListBox` provider preparation now derives visible item indexes from `TopIndex`, `ItemHeight`, and `ClientHeight` instead of probing each visible row with `ItemRect`.
- Fixed-height `TListBox`/`TCheckListBox` item bounds now reuse prepared listbox geometry and bypass Delphi's `ItemHeight` getter, avoiding hidden `LB_GETITEMRECT` calls during UIA bounds queries.
- Focus and hover speech now rejects obvious long value/help mismatches before copying the candidate prefix, avoiding avoidable allocation on the speech cleanup path.
- Focus and hover speech now compares long ASCII value/help prefixes in place before falling back to Unicode `CompareText`, avoiding another prefix-copy allocation when similar texts diverge after the first character.

## 2026-07-08
### Added
- The desktop-control helper `fast-map` now supports `--detail full`, so bridge-enabled VCL apps can return visible captions, values, hints, roles, and native checked/selected/list state through process-local VCL/RTL reads instead of a semantic UIA tree walk.
- Agent bridge `form.map` responses now include in-process elapsed timing fields, making bridge map performance separable from Python, PowerShell, UIA traversal, and client JSON overhead.
- Agent bridge `control.info` can now enrich one existing snapshot ref with process-local VCL caption, value, hint, and native state data, letting automation pair cheap geometry maps with targeted detail reads instead of broad UIA tree walks or full-form scans.
- The desktop-control helper `uia-map` now marks its output as recommended for semantic verification, not coordinate discovery, and returns faster alternatives so automation can branch to `fast-map`, `bridge-form-map`, or `win32-map --detail geometry` without parsing prose.
- The desktop-control helper `uia-map --cache` now uses .NET UIAutomation cache requests for bounded semantic UIA snapshots, avoiding separate property round trips for common fields when UIA itself must be verified.
- The desktop-control helper `uia-map` can now start from a resolved target HWND and cap child enumeration per node, making semantic UIA probes easier to keep narrow when native `fast-map`/`win32-map` is not enough.
- The desktop-control helper `uia-map` now supports `--detail geometry` to skip semantic UIA property reads when only rectangles and tree shape are needed.
- The desktop-control helper `win32-map` now supports `--detail geometry`, and `fast-map` uses that Win32 fallback to skip per-HWND title reads when only native coordinates are needed.
- The desktop-control helper `fast-map` now auto-tries the MaxLogic bridge default pipe from a PID, focused window, HWND, or title-matched target before falling back to generic Win32 geometry discovery.

### Fixed
- Native checkbox/radio hover now skips provider UIA event batching when no UIA clients are listening, while still raising the native WinEvents that preserve screen-reader state speech.
- Hint notification paths now skip provider UIA event batching when no UIA clients are listening, avoiding empty hover/hint event batches during silent automation or non-screen-reader runs.
- Native checkbox/radio focus messages that rely on native HWND state events now bypass provider UIA event batching when no supplemental UIA speech is emitted.
- The desktop-control helper `fast-map --pid` now resolves the process window to a native HWND before probing the MaxLogic bridge, so background target discovery maps the intended form instead of the currently focused form.
- The desktop-control helper `fast-map` now preserves in-process bridge timing as `bridgeElapsedMs`/`bridgeElapsedTicks` instead of overwriting it with helper wall-clock time.
- The desktop-control helper `uia-map` now defaults to the cached .NET UIAutomation traversal and keeps the slower Python `uiautomation` traversal behind `--plain`, reducing accidental broad semantic UIA property round trips.
- The desktop-control helper `win32-map --max-children` now stops native sibling traversal at the requested cap instead of enumerating every child and truncating afterward, keeping wide HWND trees responsive.
- The desktop-control helper `uia-map --max-children` now uses capped sibling traversal when available instead of materializing every child before truncating, reducing broad UIA map latency on wide trees.
- The desktop-control helper `fast-map` now keeps automatic MaxLogic-bridge probes short before falling back to Win32, so generic applications without the bridge do not pay the full command timeout.
- Additional static UIA provider properties (`AutomationId`, `FrameworkId`, `ItemStatus`, and `ItemType`) now avoid per-provider dictionary allocation during provider creation and property reads.
- Provider direct-child enumeration now prepares a child snapshot once per count/index pass instead of re-preparing for every indexed child, reducing small UIA tree traversal latency for virtual child providers such as visible grid cells.
- TMS `TAdvStringGrid` sibling navigation now reuses the prepared visible-cell snapshot instead of refreshing visible cells for every next/previous sibling traversal.
- Radio-group child-window binding now resolves framework child providers through direct in-process child access instead of UIA `Navigate`, removing provider-boundary traversal from custom `TRadioGroup` hook setup.
- The desktop-control helper `uia-map` now reports elapsed time after the UIA tree snapshot is materialized, so timing evidence includes the slow semantic traversal instead of only setup.
- The desktop-control helper `uia-map --cache` now passes its .NET UIAutomation `CacheRequest` into TreeWalker child/sibling calls, so descendant properties are cached instead of falling back to per-property UIA reads.
- Form installation now walks framework-owned provider child trees through direct in-process child access before falling back to UIA `Navigate`, avoiding provider-boundary traversal work on large VCL forms.
- Root fallback hit testing now walks framework-owned provider children through direct in-process child access instead of UIA `Navigate`, reducing mouse-hover hit-test work for page-control/container body points.
- Root fallback hit testing now computes framework-owned VCL provider bounds through native control geometry instead of provider `Get_BoundingRectangle` callbacks, removing another provider-boundary cost from container/body hover points.
- Internal provider hit-test descent now calls child bounds through the provider-core virtual method instead of the public UIA `Get_BoundingRectangle` wrapper, removing one provider-boundary callback per candidate child.
- Provider fragments now cache their nearest fragment root when attached, avoiding repeated parent-chain walks on UIA `Get_FragmentRoot` callbacks during tree traversal.
- Agent bridge geometry maps now carry parent client origins through recursive traversal, avoiding repeated parent-chain coordinate reconstruction for non-windowed VCL descendants.
- Hint notification paths now check for listening UIA clients before parsing or cleaning hint text, avoiding unnecessary VCL hint work during silent runs and non-screen-reader automation.
- Native-owned checkbox/radio hover now skips full framework announcement-text construction when native UIA/MSAA focus and state events own the speech result.
- Repeated form/control hover over the same leaf now skips redundant UIA client-listener probes and reuses the event-batch listener result for the actual hover notification, reducing high-frequency mouse-move overhead.
- Native-owned `TListBox`/`TCheckListBox` arrow-key handling now exits through the VCL window procedure before framework listener checks, HWND-publication checks, or item-state probes run on the rapid navigation path.
- Native `TListBox`/`TCheckListBox` child `WM_GETOBJECT` requests now pass through to VCL when the framework provider does not publish that HWND, avoiding framework MSAA interception during rapid screen-reader list navigation.
- MSAA child enumeration now reads framework provider children directly instead of walking siblings through UIA `Navigate` callbacks, avoiding repeated provider-boundary round trips during screen-reader tree exploration.
- `TMemo` provider preparation now uses native edit-control line count for cache invalidation instead of full window-text length, keeping large memo navigation responsive on long text buffers.
- Multi-select `TListBox` and `TCheckListBox` UIA selection queries now read selected indexes through native listbox messages and create providers only for selected rows instead of probing every item.
- Scan trees now cache their flattened node order and return a fresh copy per query, avoiding repeated recursive traversal when tooling asks for the same tree repeatedly.
- Leaf UIA provider nodes now allocate child storage only after children are added, avoiding one list allocation per leaf provider in provider-tree snapshots and traversal.
- Focus and keyboard speech helpers now skip announcement text construction when UIA reports that no clients are listening, avoiding unnecessary row/text composition during silent automation or non-screen-reader runs.
- Framework provider focus speech now reads name, value, and help text through one in-process speech-property batch instead of three separate manager-side detail probes.
- Scanner text extraction now caches RTTI property lookups for the duration of a form scan, avoiding repeated `GetPropInfo` work on large legacy forms with many controls of the same custom class.
- Agent bridge full form maps now cache fallback RTTI property lookups per request, avoiding repeated `GetPropInfo` work on large legacy forms with many controls of the same custom class.
- Agent bridge full/native maps now avoid RTTI misses for known-empty `Caption`/`Text` fields on common stock VCL controls, keeping the process-local automation bypass cheaper on large forms.
- Grid keyboard/change hooks now exit before provider event batching when UIA reports that no clients are listening, avoiding extra key-path work in silent automation and non-screen-reader runs.
- Grouped radio-button arrow handling now checks UIA listener state before state capture and skips selection scans and provider event batches when no UIA client is listening.
- Mouse-hover speech helpers now skip provider hit-testing and announcement text construction when UIA reports that no clients are listening, while preserving native/MSAA hover events for controls that keep their native accessibility.
- `TStringGrid` and TMS `TAdvStringGrid` visible-provider refresh now creates scratch prune lists only when stale providers actually exist, eliminating that allocation from the common speech-navigation path.
- Row-select `TStringGrid` row bounding rectangles now inspect only fixed and visible columns instead of every column, keeping wide-grid focus and bounds queries responsive for screen readers.
- `TMemo` line providers now read individual visible lines through native edit-control messages instead of copying the entire memo text per line, keeping large memo preparation tied to visible lines rather than total text size.
- `TStringGrid` cell bounding rectangles now reuse a single native visible-cell rectangle lookup instead of probing visibility and geometry separately.
- `TMemo` visible-line preparation now avoids copying and cleaning line text just to create child providers; line text is read only when UIA asks for the line name.
- The `MemoListStatus` UIA probe now validates the native-HWND listbox focus speech path instead of expecting a duplicate framework notification from listbox arrow-key navigation.
- Agent bridge named-pipe clients can now send multiple sequential request/response lines on one connection, and the desktop-control helper exposes this through `bridge-batch` to avoid repeated pipe/helper setup during automation loops.
- Desktop-control bridge clients now retry while the single-instance named pipe is being recreated, avoiding transient "pipe not available" failures during rapid request loops.
- Agent bridge hit testing now rejects off-point child branches before descending into them, avoiding whole-subtree traversal when a target point is outside a nested container.
- Agent bridge visible geometry maps now check child visibility top-down instead of rewalking each control's ancestor chain, keeping deep or heavily nested form snapshots close to linear time.
- Agent bridge geometry maps now skip child-client-origin conversion for leaf windowed controls, derive child bounds from cached parent origins, and cache the focused HWND once per snapshot; diagnostics expose `agentBridgeChildClientOriginProbeCount` and `agentBridgeFocusProbeCount` to catch regressions in those hot paths.
- Agent bridge geometry maps now derive nested `TPanel` child origins from cached screen rectangles instead of probing `ClientToScreen` at every panel depth, keeping deep legacy panel maps close to linear time.
- Form installation now indexes child hooks by VCL control instead of scanning previously hooked controls for every child, keeping large legacy form install work linear.
- Grid keyboard speech batches now reuse the already-known UIA listener state, avoiding a duplicate listener probe per arrow-key announcement burst.

## 2026-07-07
### Fixed
- `TRadioGroup` item providers are now present from initial provider-tree construction and child HWND hooks bind by wrapped VCL control identity, so mouse hover resolves item-level UIA `RadioButton` providers with selected state instead of the parent group provider.
- UIA runtime-id callbacks now fill the returned SAFEARRAY in one contiguous write pass instead of one `SafeArrayPutElement` call per value, reducing provider-boundary allocation overhead during screen-reader tree traversal.
- TMS `TAdvStringGrid` selection queries now fill their one-item UIA selection SAFEARRAY through direct data access, matching the faster VCL grid/listbox provider path.
- `TGroupBox` and `TRadioGroup` windows now return their own UIA group providers, so mouse tracking over blank group areas resolves the group caption instead of the form title.
- `TRadioButton` controls inside a `TGroupBox` now use the framework radio-button provider with selection semantics and focus notifications; standalone radio buttons still preserve their native HWND accessibility path.
- Keyboard focus and arrow-key navigation on `TRadioGroup` items and grouped `TRadioButton` controls now raise supplemental framework UIA notifications so screen readers receive the focused or newly selected radio caption.
- `TListBox` and `TCheckListBox` keyboard navigation now stays on the native HWND accessibility path, avoiding duplicate framework notifications and custom provider state probes during rapid arrow-key movement.
- Native-listbox keyboard navigation now caches framework HWND-publication checks per current handle, avoiding repeated provider-property checks on the rapid key path.
- Native-listbox arrow-key handling now skips grid-focus probes entirely, avoiding wasted grid-provider checks on the rapid navigation path.
- Native-listbox arrow-key handling now also skips framework item-index probes and empty post-message event batches when the native HWND provider owns speech.
- Repeated hover over the same leaf provider now reuses the last leaf bounding rectangle, avoiding redundant root hit testing while still resolving a different leaf under the pointer.
- Mouse hover over simple VCL leaf controls now resolves providers through the root control-to-provider lookup, avoiding root provider hit testing before raising hover speech.
- Common static UIA provider properties now avoid per-provider dictionary allocation.
- Row-select `TStringGrid` provider refresh now scans fixed and visible rows instead of every row when screen readers query focus or selection on large grids.
- UIA speech event bursts now reuse one `UiaClientsAreListening` probe per input-message batch, avoiding repeated listener checks for grouped radio, hover/state, and grid focus announcements.
- Prepared `TListBox` and `TCheckListBox` item providers now reuse cleaned item text for repeated UIA `Name` property queries, reducing per-callback work during screen-reader enumeration.
- HWND-backed UIA providers now advertise override-provider options and guard native host-provider lookup against re-entering the framework `WM_GETOBJECT` handler.
- Child `WM_GETOBJECT` handling now skips framework UIA handoff for providers that do not publish the child HWND, avoiding predictable UIAutomationCore rejection round trips for layout/native controls.
- Published HWND-backed UIA providers now cache native host-provider lookup results for their HWND lifetime, avoiding repeated UIAutomationCore host lookup and re-entry guard work during provider enumeration.
- Form-root providers now use the UIA `Window` control type, and listbox provider preparation no longer rebuilds children for focus-only item changes.
- Custom HWND-backed framework providers now publish native window handles only when UIA needs to bind that control fragment, fall back to native handling when UIA rejects a provider, and resolve embedded child fragments to the nearest fragment root.
- The agent bridge now exposes provider-hotspot diagnostics so a running application can report UIA provider boundary call counts while an external probe drives it.
- Diagnostics logging now avoids formatting provider descriptions and querying provider properties on `ElementProviderFromPoint` and `WM_GETOBJECT` hot paths when logging is disabled.
- Blank `TPanel`/layout-panel containers are no longer emitted as extra UIA pane nodes just because they contain accessible descendants; their children remain exposed directly.
- `TListBox` and `TCheckListBox` providers now keep their native HWND identity internally without publishing it through the framework UIA provider, so `AutomationElement.FromHandle` and screen-reader focus speech use the fast native listbox provider while the framework tree still supports hit testing and selection queries.
- VCL root providers now expose a native control-to-provider lookup, avoiding recursive UIA fragment tree walks when framework hooks need to resolve a known VCL control.
- `TStringGrid` and TMS `TAdvStringGrid` keyboard navigation now resolve the focused cell provider directly for speech events instead of refreshing visible cell providers first.
- The agent bridge `form.map` now includes UIA-equivalent role IDs/names and role-specific native state, giving automation a process-local VCL/RTTI bypass for common UIA property queries.
- Non-published child HWND fragments no longer advertise UIA native-provider override options, avoiding unnecessary UIAutomationCore native-merge navigation and property probes during broad tree traversal.
- Focus and hover speech helpers now read framework provider names, hints, control types, and values through an in-process provider path before falling back to UIA property/pattern calls.
- Provider state capture now reads framework toggle and selection state through in-process VCL provider properties and skips impossible pattern fallbacks, removing provider pattern callbacks from grouped-radio arrow speech.
- Provider state capture now also skips impossible toggle/selection pattern probes for grid keyboard navigation, removing two extra provider pattern callbacks from each `TStringGrid` and TMS `TAdvStringGrid` arrow-key speech update.
- MSAA speech property reads now use in-process provider access for framework providers, avoiding extra UIA provider boundary callbacks when screen readers query name, role, value, and state.
- MSAA tab default-action queries now use direct in-process pattern support checks for framework tab items, avoiding an extra provider pattern callback when screen readers ask for the tab action text.
- MSAA provider wrappers now cache direct-access support once, avoiding repeated interface lookups while screen readers query name, role, state, value, and help text for the same framework element.
- Direct toggle/selection state reads now bypass redundant pattern-support probes, so framework and MSAA state composition use native provider properties first.
- Text cleanup now keeps already-clean text on a fast path and strips VCL accelerators with a single pre-sized buffer, reducing per-item speech work for list and grid navigation.
- Single-select `TListBox` and `TCheckListBox` UIA selection queries now build the one-item result directly, avoiding a transient provider-list allocation.
- Repeated `TListBox` and `TCheckListBox` UIA child navigation now avoids repeated `LB_GETITEMHEIGHT` window messages for fixed-height listboxes.
- Prepared `TListBox` and `TCheckListBox` sibling navigation now uses cached provider indexes instead of re-querying listbox window state on every `NextSibling`/`PreviousSibling` step.
- Prepared `TMemo` and `TStringGrid` sibling navigation now reuses the current visible child snapshot instead of re-preparing visible lines or cells on every `NextSibling`/`PreviousSibling` step.
- Row-select `TStringGrid` speech text now scans only fixed and visible columns instead of every column in wide grids.
- `TStringGrid` and TMS `TAdvStringGrid` visible-cell refresh now avoids temporary row/column range lists on speech-navigation paths.
- Scanner, bridge snapshots, and VCL providers now read/write common VCL caption, text, hint, and state properties directly before falling back to RTTI, and scanner node flattening avoids repeated dynamic-array growth.
- Provider-hotspot diagnostics now include elapsed tick totals for UIA provider boundary callbacks, making it easier to distinguish framework callback work from UIA/client traversal overhead.
- Agent bridge and desktop-control guidance now explain that small UIA tree samples can still be slow because they perform many client/provider boundary calls, and recommend bridge geometry maps or Win32 maps for fast control discovery.
- `form.map` now supports `includeAccessibility:false` for fast native VCL coordinate/state snapshots when automation does not need accessible-name/help-text scanning.
- `form.map` now supports `visibleOnly:true` so automation can request only currently visible controls and skip hidden or inactive tab-page descendants on large forms.
- `form.map` now supports `detail:"geometry"` for the fastest bridge control-targeting snapshot, returning VCL refs, roles, handles, rectangles, and target points while skipping UIA traversal, accessibility scanning, text RTTI, and native state reads.
- `form.map` no longer creates HWNDs for controls that have not allocated one yet; unallocated controls report handle `0` while still returning process-local geometry.
- The agent bridge named-pipe server now grows request buffers in chunks instead of resizing once per byte for large control requests.
- The Windows desktop-control skill helper now includes `win32-map`, a generic User32 HWND-tree snapshot for fast title/class/rectangle discovery before falling back to UIA tree traversal.
- Agent bridge `keyboard.tab` now delegates to VCL's native tab traversal instead of rebuilding and sorting a custom tab-stop list, improving large-form background/foreground drive responsiveness.
- Scanner label association now resolves explicit `TLabel.FocusControl` captions through a per-parent native map, avoiding per-edit sibling rescans on large legacy forms with many labeled text inputs.
- Scanner child ordering now bypasses generic sorting when VCL children are already in component order, reducing scan work for the common ordered-control case while preserving stable reordered-form traversal.

## 2026-06-30
### Added
- Added provider hotspot diagnostics for memo line preparation, VCL `TStringGrid` refresh, TMS `TAdvStringGrid` refresh, and listbox `GetSelection` so performance work can be driven by measured provider-query costs.

### Fixed
- Memo provider navigation now prepares only visible logical lines plus an out-of-view caret line instead of creating providers for every memo line.
- VCL `TStringGrid` provider refresh now scans fixed and visible rows/columns instead of the full grid, reducing provider-query work for large grids.
- Memo hit-test coordinate decoding now avoids Delphi range-check errors when Windows returns signed coordinate values.
- TMS `TAdvStringGrid` provider refresh now scans fixed and visible rows/columns instead of the full grid while preserving explicit off-screen cell requests.

## 2026-06-29
### Fixed
- `TListBox` and `TCheckListBox` focus changes no longer queue an extra UIA notification for the same focused item, reducing duplicate screen-reader speech.
- Large listbox provider preparation now scans visible rows instead of every item, improving focus-change responsiveness in hosts with long list controls.
- Repeated unchanged listbox provider navigation now reuses the prepared visible/focused item state instead of re-scanning rows, reducing UIA work during screen-reader focus queries.
- Cached listbox item providers now avoid repeated item-text cleanup on unchanged focus queries while still dropping cached items whose text becomes empty.

## 2026-06-26
### Added
- Added `TAccessibilityManager.Run(Application)` as a one-call app-wide lifecycle helper that installs accessibility, runs the VCL message loop, and uninstalls on shutdown.
- Added `MaxLogic.Accessibility.AgentBridge`, a VCL-main-thread JSON command executor for diagnostic automation with framework handshake, form maps, VCL hit testing, and gated mutation commands.
- Added `MaxLogic.Accessibility.AgentBridge.PipeServer`, an opt-in local named pipe transport for the agent bridge.
- Added explicit `--a11y-agent-bridge` diagnostics switches to the complex demo.

### Fixed
- `TGroupBox` and `TRadioGroup` hovers now raise a UIA focus event for the group provider before the existing notification, improving screen-reader mouse tracking for group captions.
- `TRadioGroup` item hover now keeps the item focus event and also emits an item-caption notification for the virtual radio button provider, covering screen readers that ignore focus-only events for the internal group button.
- `TRadioGroup` item hover now hooks VCL's private item button windows, so real mouse movement reaches the item provider instead of stopping at the group caption.
- Non-client mouse hover, including over the window close button, no longer trips Delphi range checking while converting signed mouse coordinates.
- `TCheckBox` and standalone `TRadioButton` hover now keep the native HWND accessibility path, raise a state-capable UIA focus event from the framework provider, and nudge the native HWND with focus/state WinEvents so screen readers can query localized checked/selected state without framework-injected English state text.
- `TGroupBox` hover now handles non-client mouse movement over the frame/caption.
- `TRadioGroup` internal button hover now routes to the framework radio-item provider instead of preserving the private child `TRadioButton` native path, so the item caption/state surface is reachable under the mouse.

## 2026-06-24
### Added
- Added `TAccessibilityScreenReaderDetector` for optional framework activation based on Windows `SPI_GETSCREENREADER` and UIA client-listener signals.
- The demo now includes a `TGroupBox` with two `TRadioButton` controls and a separate `TRadioGroup` for radio-button role/state testing.
- The demo now includes a checked-by-default `Accessibility enabled` checkbox that can disable and re-enable the framework at runtime.

### Fixed
- The demo now uninstalls accessibility hooks after `Application.Run` and disables its balloon timer during form destruction, preventing shutdown-time callbacks into torn-down VCL state.
- `TCheckBox` mouse-over now raises platform object/state events instead of plain notification-only speech, while checkbox state is exposed through UIA TogglePattern and MSAA checked/mixed flags so screen readers can localize it.
- `TRadioButton` providers now expose UIA RadioButton/SelectionItem semantics and MSAA radio-button checked state.
- Standard VCL combo boxes, page controls, group boxes, radio groups, toolbars, tool buttons, and status bars now resolve to intentional UIA/MSAA roles instead of generic text/client fallbacks where a standard role exists.

### Changed
- The demo checkbox hint now says `Includes archived rows in the demo grids` instead of procedural toggle text.

## 2026-06-23
### Changed
- Row-select `TStringGrid` row announcements now expose visible cells as `Column header: value` pairs separated by blank lines, improving the grouping screen readers receive for whole-row selection.

### Fixed
- `TButton` mouse-over now exposes caption and hint text through the framework, covering the demo's `Apply Filters`, `Regular Hint`, and `Close` buttons.
- `TCheckBox` mouse-over now exposes caption and help text, and checkbox providers expose UIA Toggle support plus platform state.
- Unsupported focusable windowed controls without a framework adapter now keep their native `WM_GETOBJECT` accessibility path, preserving controls that already provide their own accessibility such as `TVirtualStringTree`.
- `TMemo` mouse-over now exposes the text line under the pointer through UIA instead of falling back to the memo container.
- `TListBox` mouse-over and arrow-key selection changes now announce the individual item text.
- `TListBox` selection providers now expose all selected items for multi-select lists and tolerate item removal after a UIA item was cached.
- `TStatusBar` mouse-over now exposes the visible status text instead of only announcing a generic status-bar control name.

### Added
- The demo now includes separate no-wrap and wrapped `TMemo` tabs for comparing NVDA mouse-over behavior.

## 2026-06-22
### Added
- The demo now has separate regular `TStringGrid` tabs for row-select and cell-select keyboard testing.
- Debug demo builds can write a madExcept AI `bugreport.txt` when launched with `MAXLOGIC_MADEXCEPT_AI=1`.

### Fixed
- Keyboard focus on `TEdit`, `TComboBox`, and `TLabeledEdit` now announces the same name/value/help surface used by mouse-over hit testing.
- Windows UIA object-under-mouse hit testing now returns `TTabSheet` tab items for page-control tab captions and active tab header `TLabel` providers above the grids instead of the generic `PageControl` container.
- `TPageControl` tab captions now raise tab-caption hover notifications through the installed runtime hook path.
- Labels inside active tab-sheet header panels now raise label hover notifications on mouse-over without stealing grid cell speech.
- Row-select `TStringGrid` keyboard movement now announces the whole selected row while cell-select grids continue to announce the focused cell.

## 2026-06-21
### Fixed
- `TStringGrid` and TMS `TAdvStringGrid` keyboard navigation now emit the current row/cell notification from the focused cell provider and suppress the grid HWND focus event that could make NVDA append the grid name after each move.
- Active `TTabSheet` providers now expose tab-header-only bounds, while form-root hit testing still reaches visible active-tab content and keeps inactive-tab grids hidden.
- `TPageControl` tab headers now expose MSAA selectable/selected state and a default switch action, giving NVDA a cleaner page-tab object on hover.
- Text inputs now expose associated labels as their UIA name and their entered/selected text through UIA ValuePattern, improving mouse-over and tab-focus announcements for `TEdit`, `TComboBox`, and `TLabeledEdit`.
- `TStringGrid` and TMS `TAdvStringGrid` hit testing now ignores grids hidden by inactive tab pages and verifies the real VCL window under the pointer before returning cell providers.
- Focused controls now raise UIA notifications for hint text and `TEdit.TextHint`, and grid current-cell changes raise UIA focus/selection wiring for the new current cell.
- Windowed input focus now raises a UIA focus-changed event from the installed child provider, restoring keyboard tab announcements for associated-label inputs.
- `TEdit` providers now use the UIA Edit control type and include `TextHint` placeholder text in help text.
- Empty `TEdit` providers now expose `TextHint` through UIA ValuePattern as a placeholder fallback.
- `TPageControl` tab-header hit testing now prioritizes the actual tab header under the mouse, so the active tab page no longer masks sibling tab buttons.
- Keyboard focus on windowed inputs now emits a classic MSAA focus WinEvent on the default runtime path, improving NVDA announcements when it enters through MSAA instead of UIA.
- Windowed VCL providers now expose their native HWND so screen readers can resolve installed child providers from native controls.
- The demo balloon hint timer now closes the visible balloon directly instead of leaving the sample hint open.

### Changed
- The demo includes icon-only glyph `TSpeedButton` samples with explicit short/long hints for screen-reader testing.

## 2026-06-20
### Fixed
- Grid hit testing now ignores points outside the grid bounds, preventing inactive grids from stealing mouse-over results from labels, buttons, panels, or another grid.
- Framework `WM_GETOBJECT` handling now answers `OBJID_CLIENT` requests as well as UIA root requests, allowing screen readers that enter through the client-object path to receive framework providers.
- Child window `WM_GETOBJECT` handling now returns framework UIA providers, so windowed controls such as `TLabeledEdit`, `TStringGrid`, and `TAdvStringGrid` do not fall back to native edit/row providers.
- Container child windows now route UIA hit testing through the form root, allowing non-windowed labels inside panels and tab pages to resolve to the deepest label fragment under the pointer.
- Form-root hit testing now walks the provider tree by bounding rectangle and returns the deepest matching fragment.
- `TLabeledEdit` text extraction now uses `EditLabel.Caption` before the edit text.

### Changed
- The demo now writes `AccessibilityComplexDemo.a11y.log` beside the EXE with framework `WM_GETOBJECT` and UIA hit-test diagnostics for NVDA correlation.
- The demo no longer uses grid mouse-move hint notifications for per-cell speech; it relies on the framework UIA providers instead.
- The demo balloon hint now auto-hides after a short interval.

## 2026-06-18
### Fixed
- TMS `TAdvStringGrid` merged-cell UIA spans now count only visible rows and columns when hidden coordinates are inside the merged range.
- Custom/balloon hint announcements now use the final hint text after a control mutates `Hint` in `OnMouseEnter`.
- Disabled `TSpeedButton` UIA Invoke/Toggle automation no longer triggers button clicks or toggles `Down`.

### Added
- Added custom adapter registry overloads for `TAccessibilityManager.Install(Application, Registry)` and `Install(Form, Registry)`, enabling opt-in TMS `TAdvStringGrid` support through the manager path.
- Added adoption documentation, UIA probe documentation, and an NVDA manual checklist for the current VCL accessibility coverage.
- Added opt-in UIA DataGrid/cell provider support for TMS `TAdvStringGrid`, including stripped HTML text, wide text fallback, per-cell hit testing, current-cell focus, hidden row/column remapping, and scrolled-cell pruning.
- Added UIA DataGrid/cell provider support for VCL `TStringGrid`, including per-cell hit testing, current-cell focus, and hidden-cell omission.
- Added UIA notification support for VCL hints and balloon hints, including app-wide/scoped install wiring and duplicate-speech suppression.
- Added UIA-first VCL adapters and probe coverage for labels, speed buttons, panels, and generic graphic controls.
- Added a VCL form scanner, adapter registry, text extraction fallback pipeline, and runtime control-change observer.
- Added `TAccessibilityManager.Install(Application)` and `Install(Form)` entry points for app-wide and scoped form accessibility installation.
- Added UI Automation provider core support for fragments, runtime IDs, lifecycle disconnects, and gated UIA events.
- Added Delphi UI Automation core bindings for the first provider implementation slices.
