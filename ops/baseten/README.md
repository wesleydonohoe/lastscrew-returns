# Baseten — packaging QA model

We don't ship a Truss in this repo. Pick a hosted multimodal model from
Baseten's catalog and wire its keys into `.dev.vars`. Recommended:
**Qwen2-VL-7B-Instruct**.

## Deploy

1. Go to https://www.baseten.co/library and search for `Qwen2-VL-7B-Instruct`.
2. Deploy. Wait for the model to land in the "Active" state.
3. From the deployment's **Call model** tab, grab:
   - `BASETEN_MODEL_ID` — the `<id>` in `model-<id>.api.baseten.co`.
   - `BASETEN_API_KEY` — from your account → API keys.

## Configure

```env
# .dev.vars
BASETEN_API_KEY=...
BASETEN_MODEL_ID=...
```

Restart `npm run dev`. Hit `/api/health` and confirm `baseten: true`.

## Smoke test

```bash
curl -X POST http://127.0.0.1:8787/api/lastscrew/verify \
  -H 'content-type: application/json' \
  -d '{
    "orderId": "WF-ORDER-8821",
    "imageUrl": "https://images.unsplash.com/photo-1607082348824-0a96f2a4b9da",
    "photoDescription": "cardboard box, taped seams"
  }'
```

You should see `"source": "baseten"` in the response. If you see
`"source": "mock"`, the worker didn't read your keys — check `.dev.vars` and
restart `wrangler dev`.

## Custom Truss (optional)

If you want a model fine-tuned on packaging photos, drop a Truss under
`ops/baseten/truss/` and deploy with:

```bash
cd ops/baseten/truss
truss push
```

Then point `BASETEN_MODEL_ID` at the new deployment.
