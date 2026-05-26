# Packaging QA via Baseten

The packaging-QA step is what makes the financials work. Wayfair's warehouse
intake + QA is the single biggest cost we're skipping — so we have to
*replace* it with something trustworthy. That's the Baseten-hosted vision
model.

Source of truth: `src/baseten/client.ts` (the client + prompt + mock).

## Pick a model

For a hackathon, pick a hosted multimodal model from Baseten's library:

- **Qwen2-VL-7B-Instruct** — solid default. Returns JSON when you ask.
- **LLaVA-NeXT-13B** — heavier but more reliable on tricky photos.
- A **custom Truss** if you want to fine-tune on a packaging dataset.

Deploy on Baseten, copy the model id and API key into `.dev.vars`:

```env
BASETEN_API_KEY=...
BASETEN_MODEL_ID=...
```

The endpoint we hit is
`https://model-${BASETEN_MODEL_ID}.api.baseten.co/production/predict` with an
OpenAI-style chat completions payload (`messages` with `image_url`).

## The QA prompt

```
You are a packaging quality inspector for Wayfair's "Last Screw" return program.
The user has kept an assembled furniture item and is now repackaging it as a
micro-warehouse host.

Look at the photo and score whether the packaging is shippable. Score each item:
1. Item fully wrapped (blanket / shrink / original wrap)
2. Corners and edges padded
3. Original box OR comparable rigid container
4. Box closed and taped
5. Shipping label area clear and dry
6. No visible damage, stains, or wet spots

Return STRICT JSON only:
{
  "verdict": "pass" | "needs_work" | "fail",
  "score": <0..1>,
  "checklist": [{"label": "...", "passed": true|false, "detail": "..."}],
  "notes": "<one short paragraph>",
  "bonusMultiplier": <0..1.2>
}
```

The `bonusMultiplier` is the lever that ties QA back into the pricing model.
A pristine package gets `1.15×` the resale bounty; a borderline one gets
`0.85×`. That structure incentivizes the host to do this *right*.

## Mock mode

When `BASETEN_API_KEY` / `BASETEN_MODEL_ID` are missing, the client returns a
deterministic `mockQA(photoDescription)`. Three modes:

- description contains *"torn / wet / damage / stain / open / no box"* → `fail`
- description contains *"wrapped / taped / padded / box / label / dry / clean"* → `pass`
- anything else → `needs_work`

This keeps the iOS demo working when Baseten is offline.

## Failure modes worth knowing

- **Hallucinated checklist.** Some VLMs invent checklist items not in the
  prompt. We tolerate this — the iOS app renders whatever it gets.
- **Score-verdict mismatch.** Model says `verdict: pass` but `score: 0.4`. We
  surface the lower of the two on the UI so the host sees the truth.
- **Latency.** Real Baseten calls can take 4–8s. The iOS shutter button shows
  a progress spinner; don't shorten this — it's part of the trust signal.
