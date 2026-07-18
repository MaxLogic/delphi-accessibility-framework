# Retained test suite audit

Date: 2026-07-18

## Characterization

The pre-change suite contained 389 tests in 16 units. The unchanged baseline passed 389/389 in a fresh Release Win32 run. Earlier complete-suite evidence reproduced two intermittent failures:

- `.agents/runs/t119-final-release.out.log`: `AdditionalStaticPropertiesAvoidDictionaryAllocation` failed a wall-clock ratio while passing in isolation.
- `.agents/runs/t119-final-release-rerun.out.log`: three TStringGrid tests failed because a synthetic `WM_KEYDOWN` did not move `Row`; their event assertions were never reached, and all passed in isolation.
- The first consolidated-candidate Debug run passed 370/371 tests but `MemoPreparationDoesNotScaleWithTotalMemoText` failed its wall-clock ratio (`1681` versus `16037` ticks) while its bounded-work counters remained correct.

This is a pure test-suite consolidation. No production behavior was changed. The retained suite contains 371 tests, a reduction of 18.

## Removed and consolidated tests

| Removed or consolidated | Reason | Retained coverage |
| --- | --- | --- |
| `CommonStaticPropertiesAvoidDictionaryAllocation`; `AdditionalStaticPropertiesAvoidDictionaryAllocation` | Removed two noisy relative-timing comparisons. | Consolidated into `StaticPropertiesUseTypedStorageAndPreserveValues`, which structurally verifies each typed-property route and functionally round-trips the additional UIA properties. |
| `CachedWrapperLatencyArtifactIsWritten` | Removed a task-specific JSON artifact writer whose only behavioral assertion duplicated export-cache coverage. | `RepeatedWrapperCallsResolveEachExportOnce` and `ConcurrentFirstWrapperUseResolvesExportOnce` retain sequential and concurrent cache contracts. |
| `MsaaObjectCacheMeasuresRepeatedGetObjectLatency` | Removed a task-specific latency artifact writer. | `MsaaObjectCacheReusesWrapperUntilCleared` retains identity, release, replacement, and direct-access query-count assertions. |
| `LogCallerLatencyArtifactIsWritten` | Removed measurement-only artifact generation with no acceptance threshold. | `LogFileWritesRunOnBackgroundThread`, `QueueOverflowDropsRecordsWithoutWaitingForWriter`, and `HotPathCallsDoNotWaitForConcurrentDisable` retain the non-blocking diagnostics contract. |
| `SupplementalEventCounterLatencyDistribution` | Removed task-specific timing output. | `SupplementalUiaEventFanoutMetricsCountTypes` plus the retained manager fanout tests assert exact typed UIA/MSAA counts. |
| `ProviderHotspotBaselineArtifactIsWritten` | Removed a historical aggregate containing completed-task decisions. | The memo, listbox, TStringGrid, and TAdvStringGrid hotspot tests retain each component counter and bounded-work assertion. |
| `ListBoxFocusBaselineArtifactIsWritten` | Removed completed-task baseline-file generation. | `CheckListBoxRapidFocusMovementUsesNativeHwndSpeechPath` retains the native HWND routing contract. |
| `ListBoxNativeHwndNavigationDoesNotProbeGridFocusPath`; `ListBoxNativeHwndNavigationDoesNotProbeFrameworkItemIndex`; `ListBoxFocusMovementUsesNativeHwndSpeechPath` | Removed exact assertion subsets and the single-step duplicate of the eight-step scenario. | Consolidated into `CheckListBoxRapidFocusMovementUsesNativeHwndSpeechPath`, including both zero grid-probe and zero framework-item-index assertions. |
| `FormInstallHoverMissCacheLatencyDistribution` | Removed an assertion-free optional CSV generator. | The retained blank-form, panel, group-box, invalidation, repaint, and passivation tests assert cache behavior directly. |
| `FormInstallListBoxSelectionTrackingLatencyDistribution` | Removed optional CSV generation and duplicate bulk-selection message limits. | `FormInstallTracksListBoxSelectionOncePerMutation` retains stable traversal and mutation reconciliation counts. |
| `RemoveLeadingDuplicateEmptyDuplicateAvoidsCopy`; `RemoveLeadingDuplicateCleanNonDuplicateAvoidsCopy`; `RemoveLeadingDuplicateLongMismatchAvoidsPrefixCopy`; `RemoveLeadingDuplicateAsciiSharedFirstCharMismatchAvoidsPrefixCopy` | Four wall-clock comparisons exercised the same no-op buffer-reuse contract. | Consolidated into `RemoveLeadingDuplicateNoOpPathsReuseInputBuffer`, which checks all four inputs and directly verifies string-buffer identity. |
| `ManagerBalloonHintTitleOnlyFollowUpIsSuppressed`; `ManagerBalloonHintImageIndexFollowUpIsSuppressed`; `ManagerBalloonHintImageIndexOnlyFollowUpIsSuppressed` | Three tests repeated the same application setup and one-shot suppression contract. | Consolidated into `ManagerBalloonHintFollowUpVariantsAreSuppressed`; each original input, follow-up, notification count, and display string remains asserted through isolated helper runs. |

## Deterministic replacements

- `CleanPlainTextFastPathBeatsPreviousCharAppendLoop` became `CleanPlainTextFastPathReusesInputBuffer`; it now proves the fast path by output and buffer identity instead of scheduler-sensitive timing.
- `RemoveLeadingDuplicateAvoidsQuadraticSeparatorTrimming` became `RemoveLeadingDuplicateUsesIndexScanForSeparatorRuns`; it retains the long-run semantic case and verifies index-scan/single-copy source structure without timing.
- `MemoPreparationDoesNotScaleWithTotalMemoText` now compares the visible-line probe and provider-creation counts for small and large memos, including the existing maximum-probe bound. This retains the scaling contract without measuring scheduler-sensitive elapsed time.
- The TStringGrid and TAdvStringGrid arrow-message tests now set the expected post-key row before dispatching `WM_KEYDOWN`. This deterministically tests our hook's message-triggered observation without treating VCL focus-dependent synthetic key dispatch as framework behavior:
  - `FormInstallRaisesGridCellFocusEventAfterStringGridArrowKey`
  - `FormInstallRaisesStringGridRowFocusNotificationForRowSelect`
  - `FormInstallSkipsStringGridFocusTextWhenNoUiaClients`
  - `FormInstallDoesNotRaiseGridMsaaFocusWinEventAfterCellNotification`
  - `FormInstallRaisesGridCellFocusEventAfterAdvStringGridArrowKey`

## Retained coverage

The audit compared all 389 implementation bodies by normalized token-shingle similarity and reviewed every high-similarity pair. Similar tests were retained when they protect different implementations or axes, including TStringGrid versus TAdvStringGrid, merged row versus column spans, inside/outside/inactive-tab hit testing, application versus form installation, focus versus hover, and diagnostics-enabled versus disabled paths.

No test is skipped or ignored. No assertion was deleted merely because it had failed. Measurement-only tests were removed only when deterministic retained tests already covered their behavioral or operation-count contract.

## Verification

- Debug Win32: 371/371 passed, zero failed, errored, leaked, skipped, or ignored tests.
- Release Win32 pass 1: 371/371 passed, zero failed, errored, leaked, skipped, or ignored tests.
- Release Win32 pass 2, run immediately on the unchanged candidate: 371/371 passed with the same zero counts.
- Project-context Pascal Analyzer completed for every touched test unit, and postprocessing verified each report's counts and ownership.
