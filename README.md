# lastscrew

> Turn the post-assembly furniture return into a micro-warehouse hosting
> program. Customers keep the assembled item, repackage it, and get paid to
> hold it until a local buyer claims it at a discount.

A hackathon concept for Wayfair, built on:

- **[Subconscious](https://docs.subconscious.dev)** — agentic reasoning that
  prices each host offer over real signals (item value, local demand, FC
  pressure).
- **[Baseten](https://docs.baseten.co/overview)** — hosts the vision model
  that QAs the host's packaging photo. That QA is what unlocks the savings
  — it replaces Wayfair's warehouse intake check.
- **Cloudflare Workers** (Hono) — the single backend the iOS app talks to.
- **SwiftUI** — the iOS app.

> **Forked from** [`subconscious-systems/hack-cloudflare-workers-starter`](https://github.com/subconscious-systems/hack-cloudflare-workers-starter)
> — the Subconscious Worker harness is the base of this repo, extended with
> lastscrew-specific tools, a Baseten client, and the iOS app.

## What's here

```
.
├── SPEC.md                 ← the parallelizable spec (read this first)
├── README.md               ← you are here
├── CONTRIBUTING.md         ← how agents (and humans) pick up workstreams
├── docs/                   ← deeper docs
│   ├── architecture.md
│   ├── api.md
│   ├── ios.md
│   ├── pricing.md          ← how the Subconscious agent prices an offer
│   ├── packaging-qa.md     ← Baseten model + checklist
│   ├── demo-script.md
│   ├── workstreams.md      ← live status of fan-out work
│   └── screenshots/        ← the Wayfair seed UI we mirror
├── src/                    ← Cloudflare Worker
│   ├── index.ts            ← Hono routes
│   ├── agent/              ← ReAct loop + tools
│   ├── lastscrew/offer.ts  ← pricing brain wrapper
│   └── baseten/client.ts   ← vision QA client + mock fallback
├── ios/                    ← SwiftUI app (xcodegen'd)
│   ├── project.yml
│   └── Sources/Lastscrew/
├── ops/baseten/            ← model deployment guide
└── scripts/                ← demo curl helpers
```

## Quick start

```bash
# 1. Worker
cp .dev.vars.example .dev.vars      # fill in SUBCONSCIOUS_API_KEY (Baseten optional)
npm install
npx wrangler kv namespace create AGENT_KV
npx wrangler kv namespace create AGENT_KV --preview
# Paste the two ids into wrangler.toml.
npm run dev                          # → http://127.0.0.1:8787

# 2. Smoke-test the full flow
bash scripts/demo-offer.sh
bash scripts/demo-verify.sh

# 3. iOS
sudo xcode-select -s /Applications/Xcode.app/Contents/Developer    # one-time
cd ios
xcodegen generate
open Lastscrew.xcodeproj
# In Xcode, pick the iPhone 15 Pro simulator and Cmd+R.
```

## Demo path

`ManageItem` → `ReturnChooser` → `OfferReveal` (Subconscious-priced) →
`AcceptHost` → `PackagingCamera` (live capture) → `PackagingResult`
(Baseten-verified) → `HostDashboard` (live earnings ticker).

Every endpoint returns a useful response **without** keys configured — the
worker falls back to a deterministic offer and a mock QA verdict so the demo
runs cold.

## License

MIT. Subconscious starter portions retain their original attribution; see
file headers in `src/agent/` and `STARTER_README.md`.
