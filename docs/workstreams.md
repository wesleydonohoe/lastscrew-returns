# Workstreams — live status

Mirrors [`SPEC.md` §4](../SPEC.md#4-workstreams). Update the **Status** and
**Owner** columns as you go. Each workstream maps to one GitHub issue with
the same WS-N tag.

| ID | Subject | Status | Owner | Files |
|----|---------|--------|-------|-------|
| WS-1 | Worker pricing + QA backend | ✅ done | initial commit | `src/index.ts`, `src/agent/tools.ts`, `src/lastscrew/offer.ts`, `src/baseten/client.ts` |
| WS-2 | iOS skeleton (project, nav, theme, API client) | ✅ done | initial commit | `ios/project.yml`, `ios/Sources/Lastscrew/{App,AppRouter,Theme}.swift`, `Networking/`, `Models/` |
| WS-3 | ManageItem + ReturnChooser screens | 🟡 first pass | _open_ | `ios/Sources/Lastscrew/Screens/{ManageItem,ReturnChooser}View.swift` |
| WS-4 | OfferReveal + EarningsBreakdown + AcceptHost | 🟡 first pass | _open_ | `ios/Sources/Lastscrew/Screens/{OfferReveal,EarningsBreakdown,AcceptHost}View.swift`, `ViewModels/OfferViewModel.swift` |
| WS-5 | PackagingCamera + PackagingResult | 🟡 first pass | _open_ | `ios/Sources/Lastscrew/Camera/`, `Screens/Packaging*.swift`, `ViewModels/PackagingViewModel.swift` |
| WS-6 | HostDashboard | 🟡 first pass | _open_ | `ios/Sources/Lastscrew/Screens/HostDashboardView.swift` |
| WS-7 | Baseten model deployment ops | ⏳ pending | _open_ | `ops/baseten/README.md` |
| WS-8 | Demo polish: README + curl scripts | ⏳ partial | _open_ | `README.md`, `scripts/` |
| WS-9 | Buyer side: nearby assembled items map (stretch) | ⏳ pending | _open_ | `ios/Sources/Lastscrew/Screens/BuyerMapView.swift`, `src/lastscrew/listings.ts` |

**Legend** · ✅ done · 🟢 in PR · 🟡 first pass merged, needs polish · ⏳ pending
