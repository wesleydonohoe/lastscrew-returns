# 90-second demo script

A walkthrough you can read aloud while running the app.

> "When you assemble a Wayfair item — say this Queen mattress and platform bed
> that takes 92 minutes — and it doesn't fit, the return policy says you get a
> 100% refund. Great. But the catch is you have to *disassemble* it, *re-box*
> it, and schedule a pickup. So a lot of customers eat the loss. Last Screw
> changes that."

1. Open the app. (`ManageItemView`)
2. Tap the **Return or replace** card.
3. "Standard return is still here. But look at this." (Tap into `ReturnChooserView`.)
4. Highlight the Last Screw card. "Keep it assembled. Earn from it."
5. Tap **See my offer**. (`OfferRevealView`)
6. "This number — $197 — wasn't hardcoded. A Subconscious agent just looked at
    the item, the local demand in my ZIP, and Wayfair's warehouse pressure,
    and decided this offer in real time. The reasoning is right here." Tap to
    show the reasoning card.
7. Tap **Accept · $50 today**. (`AcceptHostView`)
8. "$50 hit my Wayfair Rewards. Now I just wrap the item and snap a photo so
   Wayfair knows it's ship-safe."
9. Tap **Start packaging photo**. (`PackagingCameraView`)
10. Frame the box. Tap the shutter.
11. (Wait ~3s.) "That photo just got QA'd by a vision model hosted on Baseten.
     This is the step that's normally done at a Wayfair fulfillment center —
     we moved it to my phone."
12. (`PackagingResultView`) "1.15× bonus multiplier. The model verified
     everything on the checklist. Now my projected earnings climb."
13. Tap **Hand off to carrier**. (`HostDashboardView`)
14. "Earnings ticker is already running — $3 per day storage fee. When a
     neighbor claims the mattress at a 22% assembled discount, I get $90 more.
     My house just became a Wayfair node."

### Why this matters

> "Wayfair saves the return-shipping leg (~$85 for a mattress this size), the
> warehouse intake (~$25), and the restock decision (often liquidation). We're
> giving the customer up to $197 of that. Everyone wins, and the customer
> walks away as a power user of the platform — not someone who hates returns."
