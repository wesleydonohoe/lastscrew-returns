# lastscrew-packaging-vision

A Python-based Truss that wraps **Qwen2-VL-7B-Instruct** for packaging QA.

This is the model that actually looks at the photo. Without it, the Worker
falls back to the deterministic `mockQA()` that just keyword-matches a text
description — useful for development, useless for proving the concept.

## Deploy

```bash
# One-time
uv tool install truss
truss login --browser

# Push from this folder
cd ops/baseten/truss/lastscrew-packaging-vision
truss push
```

`truss push` will:
1. Bundle `config.yaml` + `model/model.py`
2. Provision an A10G GPU container on Baseten
3. Download Qwen2-VL-7B-Instruct from HuggingFace into the container
4. Start the model and run a warm-up

This takes ~5–10 minutes the first time (model download is ~16 GB).

When deployment is healthy, copy the **model id** from the logs URL
(`https://app.baseten.co/models/<MODEL_ID>/logs/...`) into `.dev.vars`:

```env
BASETEN_API_KEY=<your key>
BASETEN_MODEL_ID=<from the logs URL>
BASETEN_ENDPOINT=predict
```

`BASETEN_ENDPOINT=predict` is critical — it tells the Worker to call
`/production/predict` (Python Truss endpoint), not
`/environments/production/sync/v1/chat/completions` (which is only for the
trt_llm config-only `lastscrew-qa-reasoner`).

## Verify

Restart `npm run dev` and confirm:

```bash
curl http://127.0.0.1:8787/api/health
# { "ok": true, "baseten": true, ... }

# Try a real image
curl -X POST http://127.0.0.1:8787/api/lastscrew/verify \
  -H 'content-type: application/json' \
  -d "{
    \"orderId\": \"WF-ORDER-8821\",
    \"imageBase64\": \"$(base64 -i your-test-photo.jpg | tr -d '\n')\"
  }" | jq '.verdict, .score, .source, .checklist'
```

`source` should be `"baseten"`. Latency: ~3–8 seconds per call. Cold start
(after idle) can add 30–60 seconds.

## What the model sees

The Worker constructs a prompt with:

1. **System message**: the QA inspector instructions + strict JSON schema (see
   `QA_PROMPT` in `src/baseten/client.ts`).
2. **User message**: an `image_url` content block with the base64 JPEG, plus
   optionally a text description if the iOS app generated one with on-device
   Vision (e.g., bounding boxes around boxes / labels).

`predict()` in `model/model.py` extracts the image, runs `apply_chat_template`
+ `generate`, and returns the model output wrapped in an OpenAI-shaped
response so the Worker doesn't care which backend served the call.

## Tuning the QA rubric

Edit `QA_PROMPT` in `src/baseten/client.ts`. The model reads that prompt
directly — no re-deploy of the Truss needed. Things worth tuning:

- **Checklist items** — add or remove. Each becomes a row in the iOS result
  card.
- **bonusMultiplier scale** — currently 0..1.2. Widen if you want a stronger
  incentive gradient.
- **Strict JSON enforcement** — Qwen2-VL is usually well-behaved with explicit
  schemas but occasionally adds prose. The Worker tolerates leading/trailing
  prose around the JSON, so this is fine.

## Why not pick a model from Baseten's library?

You can — Qwen2-VL-7B is in the catalog. But we want:

1. Custom prompting baked in if we choose (we currently don't, but easy to add).
2. The ability to ship a fine-tuned packaging-specific checkpoint later.
3. A repo-level paper trail of what model is in production.

If you'd rather skip the build and just deploy from the catalog, swap the URL
in `src/baseten/client.ts` accordingly — the OpenAI-compatible shape from the
library still works, just point at its endpoint instead.
