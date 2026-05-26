# Contributing to lastscrew

This repo is built for **multiple coding agents to work in parallel**. Read
[`SPEC.md`](./SPEC.md) before touching anything.

## Pick a workstream

Workstreams are listed in [`SPEC.md` §4](./SPEC.md#4-workstreams) and mirrored
as GitHub issues. Each workstream has its own **file list** — touch only those
files. Cross-cutting changes go through `SPEC.md` and a separate PR.

When you start, comment on the issue with:

```
Claiming WS-N. Branch: ws-N-<short-name>. Files I'll touch: <list>.
```

## Branch & PR rules

- One branch per workstream: `ws-3-manage-item`, `ws-5-packaging-camera`, etc.
- Keep PRs scoped — if you discover work outside your workstream, open a
  separate issue, don't widen the PR.
- PR title format: `WS-N: <short summary>`.
- The PR template asks for: (1) workstream id, (2) files touched, (3) demo
  path verified.

## Demo path is the contract

The demo path in [`SPEC.md` §2](./SPEC.md#2-hero-user-flow-demo-path) must stay
green at all times. Run `bash scripts/demo-offer.sh` and
`bash scripts/demo-verify.sh` before opening your PR; both must succeed against
a freshly-started worker.

## Mock-friendly is non-negotiable

Every backend feature must return a useful response without a Subconscious or
Baseten key. `source: "fallback"` or `source: "mock"` is fine — silent failure
is not. See `src/lastscrew/offer.ts` and `src/baseten/client.ts` for the
pattern.

## Stay small

Three similar lines is better than a premature abstraction. Don't add a config
flag, a feature toggle, or a new dependency without saying so in `SPEC.md`
first.
