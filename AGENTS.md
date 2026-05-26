# Agent instructions for AI coding assistants

This repo is a **Cloudflare Workers hackathon starter** for building AI agents powered by the [Subconscious API](https://docs.subconscious.dev).

## Subconscious API skill

Install the official Subconscious skill so your AI assistant understands the API:

```bash
npx skills add https://github.com/subconscious-systems/skills --skill subconscious-dev
```

The skill is bundled in this repo at `.agents/skills/subconscious-dev/`.

## Architecture

```
Trigger (cron / API / webhook / button)
        ↓
  src/index.ts (Hono routes)
        ↓
  src/agent/store.ts (KV config + run history)
        ↓
  src/agent/runner.ts (tool loop)
        ↓
  src/subconscious/client.ts → api.subconscious.dev/v1
```

## Where to edit

| Goal | File |
|------|------|
| Change agent behavior | `src/types.ts` (`DEFAULT_AGENT_CONFIG`) or dashboard at `/` |
| Add tools | `src/agent/tools.ts` |
| Add API routes / triggers | `src/index.ts` |
| Change cron schedule | `wrangler.toml` → `[triggers].crons` |
| Subconscious client settings | `src/subconscious/client.ts` |

## Key env vars

- `SUBCONSCIOUS_API_KEY` — get one at [subconscious.dev/platform](https://www.subconscious.dev/platform)
- `WEBHOOK_SECRET` (optional) — protects `POST /api/webhook`

## API endpoints

- `GET /api/agent/config` — read agent config from KV
- `PUT /api/agent/config` — update agent config
- `POST /api/run` — trigger agent (`{ "instructions": "..." }`)
- `POST /api/webhook` — event trigger (optional `x-webhook-secret` header)
- `GET /api/runs` — recent run history

## Subconscious notes

- Base URL: `https://api.subconscious.dev/v1`
- Model: `subconscious/tim-qwen3.6-27b`
- Tools use standard OpenAI function calling — your Worker executes them locally
- Set `enable_thinking: false` for faster chat responses (default in this starter)

See `.agents/skills/subconscious-dev/SKILL.md` for full API details.
