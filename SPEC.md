# lastscrew — Spec

> Concept demo for Wayfair. Turn the post-assembly return into a micro-warehouse
> hosting program: the customer keeps the assembled item, repackages it, and is
> paid to hold it until a local buyer claims it at a discount.

This document is the contract multiple coding agents work against in parallel.
Each **Workstream (WS-N)** has its own files, inputs, outputs, and acceptance
criteria. Agents must stay inside their workstream's listed files unless the
change is to the shared contracts in §3.

---

## 1. Problem & pitch

**Today's flow** — customer assembled a Sleep by Wayfair™ Queen mattress + platform
bed (Order WF-ORDER-8821, ~92 min assembly), then realizes it doesn't fit. The
return-for-100%-refund path is technically free, but the friction is brutal:
disassemble the item, re-box, schedule pickup, wait. Many drop off and eat the
loss; others escalate to support.

**Lastscrew flow** — customer taps "Return" → instead of disassemble, sees:

> **Keep it assembled. Earn from it.**
> Wrap and store it in your garage. Get a $50 signing bonus today, plus
> $3/day storage, plus a $90 bonus when a neighbor claims it. We save the
> return-shipping leg and the warehouse intake; you bank the difference.

The pricing comes from a Subconscious-powered agent reasoning over item value,
local buyer demand, and FC pressure. The packaging photo is QA'd by a Baseten
vision model — that QA replaces Wayfair's warehouse intake check, which is
*the* reason this works financially.

**Why it works**
- **Logistics savings**: skip return shipping (freight tier for the mattress: ~$60–110) and skip warehouse intake/QA (~$25 amortized).
- **Resale margin**: an in-zip buyer pays ~75% of retail for an assembled, photographed unit.
- **Network effect**: each accepted host turns into a node. Wayfair effectively pays customers to become its last-mile distribution graph.

---

## 2. Hero user flow (demo path)

1. **ManageItem** — opens on the user's actual Wayfair "Manage Your Item" screen for the mattress.
2. **ReturnChooser** — taps "Return or replace my item" → sees two options side-by-side: *Standard return* vs *Last Screw return (earn $$)*.
3. **OfferReveal** — sub-second skeleton, then animates in real numbers from `POST /api/lastscrew/offer`. Shows: signing bonus, daily storage, max storage days, resale bounty, photo bonus, projected max, agent reasoning paragraph.
4. **AcceptHost** — sticky CTA "Accept · $50 today". Tap → confirmation screen "You're a host. Wrap the item, then verify packaging."
5. **PackagingCamera** — live AVFoundation preview. User shoots 1–3 photos of the packaged item.
6. **PackagingResult** — `POST /api/lastscrew/verify` shows the checklist (item wrapped, padded, taped, label dry, no damage), verdict, and the **bonus multiplier** applied to the resale bounty.
7. **HostDashboard** — running earnings ticker, days held, "package & ship" CTA when buyer is matched.

Everything off the hero path is stretch.

---

## 3. Shared contracts (do not break)

### 3.1 Worker API

Base URL (local): `http://127.0.0.1:8787`

| Method | Path | Body | Returns |
|--------|------|------|---------|
| GET | `/api/health` | — | `{ ok, subconscious, baseten }` |
| GET | `/api/lastscrew/items/:orderId` | — | `ItemDetails` |
| POST | `/api/lastscrew/offer` | `{ orderId, zip }` | `HostOffer` |
| POST | `/api/lastscrew/verify` | `{ orderId, imageBase64?, imageUrl?, photoDescription? }` | `PackagingQAResult` |
| POST | `/api/lastscrew/demo` | `{ orderId, zip, photoDescription? }` | `{ offer, qa }` |

### 3.2 Types (source of truth: `starter/src`)

```ts
ItemDetails = {
  orderId: string; sku: string; name: string;
  retailPriceUsd: number; customerPaidUsd: number;
  assemblyTimeMinutes: number;
  packagingDifficulty: "easy" | "medium" | "hard";
  dimensions: string; weightLbs: number; category: string;
  deliveredAt: string; returnReason: string;
}

HostOffer = {
  orderId: string; zip: string;
  signingBonusUsd: number;
  dailyStorageUsd: number;
  maxStorageDays: number;
  resaleBountyUsd: number;
  photoBonusUsd: number;
  projectedMaxEarningsUsd: number;
  expectedDaysToClaim: number;
  reasoning: string;
  source: "subconscious" | "fallback";
}

PackagingQAResult = {
  verdict: "pass" | "needs_work" | "fail";
  score: number; // 0..1
  checklist: { label: string; passed: boolean; detail?: string }[];
  notes: string;
  bonusMultiplier: number; // 0..1.2
  source: "baseten" | "mock";
}
```

iOS mirrors these in `Lastscrew/Models/APIModels.swift`. **If a workstream needs a new field, add it to both sides in the same PR.**

### 3.3 Demo seed

- Always use `orderId: "WF-ORDER-8821"` and `zip: "02116"` for screenshots / demos.
- The three user-uploaded screenshots (`IMG_2620/2621/2622.jpeg`) ship in `ios/Sources/Lastscrew/Assets.xcassets/`:
  - `WayfairHome` — IMG_2620 (rewards + manage orders home)
  - `WayfairManageItem` — IMG_2621 (Manage Your Item)
  - `WayfairReturnExpanded` — IMG_2622 (Return or replace expanded)

### 3.4 Brand tokens

- Primary: `#7B189F` (Wayfair-adjacent purple, slightly different so we feel like a partner not a clone)
- Accent / "earn": `#0E9F6E`
- Danger / friction red: `#C32D2D`
- Background: `#FAFAFA`
- Text primary: `#1A1A1A`
- Heading font: SF Pro Display; numbers: SF Pro Rounded.

---

## 4. Workstreams

Each workstream is independent. Owner field is for the human to fill in when
assigning to an agent.

### WS-1 — Worker pricing + QA backend  *(scaffold done)*
**Owner:** _filled — already built in this branch_
**Files:** `starter/src/index.ts`, `starter/src/agent/tools.ts`, `starter/src/lastscrew/offer.ts`, `starter/src/baseten/client.ts`
**Out of scope:** persistence (KV), auth, real Wayfair data
**Acceptance:**
- `curl -s -X POST localhost:8787/api/lastscrew/demo -H 'content-type: application/json' -d '{}'` returns both an `offer` (with `source` of `subconscious` or `fallback`) and a `qa` block.
- Health endpoint reports whether keys are configured.

### WS-2 — iOS skeleton (project, navigation, theme, API client)
**Owner:** _unassigned_
**Files:** `ios/project.yml`, `ios/Sources/Lastscrew/App.swift`, `ios/Sources/Lastscrew/Theme.swift`, `ios/Sources/Lastscrew/AppRouter.swift`, `ios/Sources/Lastscrew/Networking/APIClient.swift`, `ios/Sources/Lastscrew/Models/APIModels.swift`
**Out of scope:** any individual screen UI
**Acceptance:**
- `cd ios && xcodegen` produces `Lastscrew.xcodeproj`.
- App boots into a `RootView` that shows tabs/nav placeholders for each screen.
- `APIClient` exposes `fetchItem(orderId:)`, `requestOffer(orderId:zip:)`, `verifyPackaging(orderId:imageData:)`.

### WS-3 — ManageItem + ReturnChooser screens
**Owner:** _unassigned_
**Files:** `ios/Sources/Lastscrew/Screens/ManageItemView.swift`, `ios/Sources/Lastscrew/Screens/ReturnChooserView.swift`
**Inputs:** `ItemDetails`
**Out of scope:** offer logic — `ReturnChooser` should `navigate(to: .offer)` on the "Last Screw" path.
**Acceptance:**
- ManageItem mirrors `WayfairManageItem` asset layout but with native components, *not* a webview.
- ReturnChooser shows the two paths side-by-side with the brand purple. "Last Screw" card visually wins (badge, larger, accent gradient).

### WS-4 — OfferReveal + EarningsBreakdown + AcceptHost
**Owner:** _unassigned_
**Files:** `ios/Sources/Lastscrew/Screens/OfferRevealView.swift`, `ios/Sources/Lastscrew/Screens/EarningsBreakdownView.swift`, `ios/Sources/Lastscrew/Screens/AcceptHostView.swift`, `ios/Sources/Lastscrew/ViewModels/OfferViewModel.swift`
**Inputs:** `APIClient.requestOffer`
**Acceptance:**
- Shows skeleton loaders, then animates numbers in (SwiftUI `.contentTransition(.numericText())`).
- Earnings breakdown is a stacked bar chart of the four components summing to `projectedMaxEarningsUsd`.
- Tapping "Accept · $XX today" pushes confirmation.

### WS-5 — PackagingCamera + PackagingResult
**Owner:** _unassigned_
**Files:** `ios/Sources/Lastscrew/Camera/CameraController.swift`, `ios/Sources/Lastscrew/Camera/CameraPreviewView.swift`, `ios/Sources/Lastscrew/Screens/PackagingCameraView.swift`, `ios/Sources/Lastscrew/Screens/PackagingResultView.swift`, `ios/Sources/Lastscrew/ViewModels/PackagingViewModel.swift`
**Inputs:** `APIClient.verifyPackaging`
**Out of scope:** offline mode, multi-photo galleries (single photo for v1)
**Acceptance:**
- Live AVFoundation preview with shutter button. Capture → JPEG → base64 → POST to `/api/lastscrew/verify`.
- Result view renders checklist with green/amber/red dots, big verdict badge, and the bonus multiplier as a dial.

### WS-6 — HostDashboard
**Owner:** _unassigned_
**Files:** `ios/Sources/Lastscrew/Screens/HostDashboardView.swift`, `ios/Sources/Lastscrew/ViewModels/DashboardViewModel.swift`
**Inputs:** local state (offer + qa result combined)
**Acceptance:**
- Running earnings ticker (Timer-driven, increments `dailyStorageUsd / 86400` per second for fun demo realism).
- "Notify when buyer claims" placeholder CTA.
- "Schedule carrier pickup" placeholder CTA.

### WS-7 — Baseten model deployment ops (out-of-app)
**Owner:** _unassigned_
**Files:** `ops/baseten/README.md`, `ops/baseten/truss/` (if we ship our own Truss)
**Acceptance:**
- README explains: pick `Qwen2-VL-7B` (or similar VLM) from Baseten's model library, deploy, copy `BASETEN_API_KEY` + `BASETEN_MODEL_ID` into `starter/.dev.vars`, hit `/api/lastscrew/verify` with a real photo and confirm `source: "baseten"`.

### WS-8 — Demo polish: README + curl scripts + screenshots
**Owner:** _unassigned_
**Files:** `README.md`, `scripts/demo-offer.sh`, `scripts/demo-verify.sh`
**Acceptance:**
- One command spins up worker + opens Xcode.
- Curl scripts seed three different ZIPs to show offers diverge.

### WS-9 (stretch) — Buyer side: map of nearby assembled items
**Owner:** _unassigned_
**Files:** `ios/Sources/Lastscrew/Screens/BuyerMapView.swift`, `starter/src/lastscrew/listings.ts`, new endpoint `GET /api/lastscrew/listings?zip=`
**Out of scope:** payment, claiming flow
**Acceptance:**
- MapKit view shows 5–10 mock pins around the demo ZIP, each tappable to a listing card.

---

## 5. Running locally

```bash
# Worker
cd starter
cp .dev.vars.example .dev.vars   # fill in SUBCONSCIOUS_API_KEY (Baseten optional)
npm install
npx wrangler kv namespace create AGENT_KV         # paste id into wrangler.toml
npx wrangler kv namespace create AGENT_KV --preview
npm run dev   # → http://127.0.0.1:8787

# iOS — one-time
sudo xcode-select -s /Applications/Xcode.app/Contents/Developer
brew install xcodegen   # already installed in this repo
cd ../ios && xcodegen && open Lastscrew.xcodeproj
# In Xcode: pick an iOS Simulator (iPhone 15 Pro) and Cmd+R.
```

iOS app reads the worker URL from `Lastscrew/Networking/APIClient.swift` —
default `http://127.0.0.1:8787`. For Simulator that's fine; for a physical device,
override `LASTSCREW_API_BASE` in the scheme's environment variables.

---

## 6. Agent collaboration rules

1. **Stay in your workstream's file list.** Touching another workstream's files
   = a merge conflict factory. If you need a change in a shared contract (§3),
   include both the worker and iOS edits in your PR.
2. **No new dependencies without a note in this spec.** Anything heavier than
   what's already in `package.json` / xcodegen `project.yml` needs an explicit
   addition here first.
3. **Keep the demo path (§2) green at all times.** If your change breaks an
   earlier step, fix it or revert before opening a PR.
4. **One screen per file.** Don't combine `ManageItemView` and `ReturnChooserView`
   into one file even if "they're small."
5. **Mock-friendly.** Every endpoint must return a useful response without
   Subconscious or Baseten keys configured. Without those, `source: fallback` /
   `source: mock` is acceptable.
