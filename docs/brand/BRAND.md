# LASTSCREW — Brand & Design System  ·  *Forged* (v2.0)

> **The last screw stays in.** Skip the teardown. Keep your Wayfair piece bolted
> together, host it from home, and get paid when a neighbor claims it.

Open **`docs/brand/brand_guide.html`** for the full visual guide. This is the quick reference.

## The idea
A furniture return's real friction is the *teardown* — undoing 92 minutes of
assembly. lastscrew kills it: keep it bolted, become a one-item micro-warehouse,
and get paid to skip the round-trip to a fulfillment center. The mark is a screw
with its cross still glowing hot — don't back it out, drive it forward into the loop.

**Material:** forged steel — chrome hardware, scratched gunmetal, a molten core.
**Posture:** no fluff; real money, real freight. **Lineage:** Wayfair-adjacent —
we drop the violet, blacken everything, and light the cross on fire.

## Color
| Token | Hex | Role |
|---|---|---|
| Gunmetal / Void | `#16181C` / `#08080A` | App background, dark canvas |
| Iron / Plate | `#23262B` | Cards, surfaces, raised panels |
| Steel | `#34383F` | Borders, dividers, secondary |
| Chrome | `#E8ECF1` | Primary text + the screw body |
| Chrome Dim / Faint | `#A0A6B0` / `#6B7079` | Body copy / captions on dark |
| **Molten** | `#FF5A1F` | Brand + **every** primary action, the hot cross |
| **Acid** | `#A8FF35` | Money, earnings, "unlocked", QA pass |
| **Blood** | `#E01933` | Old return path, errors, QA fail |

Rules: it lives on dark. Selection glows **Molten**. Money is always **Acid** and
always monospace. **Blood** is the old high-friction path and failure only.

## Type
- **Display / wordmark:** Anton — all caps, heavy, condensed, tight tracking
- **Body / UI (web):** Saira
- **Mono / figures:** Share Tech Mono — payouts, order IDs, timers, QA verdicts (gauge feel)
- **In-app:** SF Pro (heavy headlines, system body), monospaced for every dollar figure.
  Bundle Anton if you want the true display face in-app.

## Logo & icon
- **Primary** (`AppIcon-1024.png` / `icon_primary.svg`) — chrome screw, molten cross.
  Ship the full-bleed square; iOS applies the squircle mask. Keep it on dark.
- **Loop mark** (`mark_loop.svg`) — chrome screw in a molten return arrow; the resell story.
- **Mono glyph** (`mark_mono.svg`) — single-color screw for favicon / tinted icon / small UI.

Do: keep the molten glow on dark — the heat is the point. Don't: put it on white,
flatten the chrome to gray, or cool the cross to a dull orange (it reads hot, white-cored).

## Voice
Sharp friend who runs logistics out of a garage. Short, blunt, real numbers, "you".
- ▶ "Keep it bolted. We'll pay you to hold it." / "A neighbor wants this one. Ship it, bank $15."
- ■ "Unlock your fur-ever rewards journey!" / "Leverage your residential node for synergy."

## Files
Source-of-truth brand assets live in `docs/brand/`:
```
docs/brand/BRAND.md            ← this doc
docs/brand/brand_guide.html    ← full visual guide (self-contained)
docs/brand/icon_primary.svg    ← vector source of the icon
docs/brand/mark_loop.svg       ← loop / resell mark
docs/brand/mark_mono.svg       ← flat monochrome glyph
docs/brand/AppIcon-1024.png    ← rendered master, 1024×1024 RGB (no alpha)
```

Shipped into the iOS app:
```
ios/Sources/Lastscrew/Assets.xcassets/AppIcon.appiconset/
  ├─ AppIcon-1024.png          ← copy of the master above
  └─ Contents.json             ← single-image universal manifest
ios/Sources/Lastscrew/Theme.swift                            ← SwiftUI tokens (forged palette)
ios/Sources/Lastscrew/Assets.xcassets/AccentColor.colorset/  ← set to Molten #FF5A1F
```
