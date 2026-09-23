# Reverse Face Search API — examples, OpenAPI spec and a fake-profile checker

Working code for **[Trace](https://traceaifacescan.app/?utm_source=github&utm_medium=referral&utm_campaign=api-repo)**, a reverse face search API: upload one photo, get back the public pages and social profiles that face appears on, each with a 50–100 similarity score.

This repository holds the OpenAPI 3.0 spec and runnable Python, Node and curl examples. It is maintained by the people who build Trace.

```bash
pip install requests
export TRACE_KEY=trk_live_...
python examples/python/check_profile.py photo.jpg @claimed_handle
```

```
 94  instagram  @real_owner              https://instagram.com/real_owner
 88  x          @real_owner              https://x.com/real_owner
 81  web        -                        https://example.com/team/…

⚠ Same face appears under 2 other account(s). Review manually.
```

## Contents

| Path | What it is |
|---|---|
| [`openapi.json`](openapi.json) | OpenAPI 3.0 spec — import into Postman, Insomnia, RapidAPI or an SDK generator |
| [`examples/python/check_profile.py`](examples/python/check_profile.py) | Fake-profile checker, ~50 lines, no SDK |
| [`examples/node/check.mjs`](examples/node/check.mjs) | Same flow in Node 18+ with `fetch` |
| [`examples/curl/quickstart.sh`](examples/curl/quickstart.sh) | The three calls, in a shell |
| [`docs/api-reference.md`](docs/api-reference.md) | Endpoints, match tiers, idempotency, limits |
| [`docs/errors.md`](docs/errors.md) | Every `code` the API can return and what to do about it |
| [`docs/comparison.md`](docs/comparison.md) | Trace vs FaceCheck.ID vs PimEyes vs Lenso, honestly |
| [`docs/catfish-checklist.md`](docs/catfish-checklist.md) | How to tell a fake dating or social profile from a real one |

## What this API is for

- **Fake-profile (catfish) detection** on dating apps, marketplaces and social platforms — does this face already belong to somebody else?
- **Trust & safety / KYC support** — flag a new signup whose photo is a stock image or a stolen profile picture.
- **Personal exposure checks** — find where your own face is published, so you can ask for removals.

It is **not** an identification service. Trace returns public URLs and similarity scores, never names, addresses or personal records. Using it to identify, locate, monitor, stalk or harass anyone is forbidden by the [terms](https://traceaifacescan.app/terms).

## How the API works

Three calls. No SDK, no webhook setup needed.

```
POST /v1/scans              multipart image  ->  202 { id, status: "queued", locked }
GET  /v1/scans/{id}                          ->  poll until status is "done"
POST /v1/scans/{id}/reveal                   ->  only if locked: spends one credit
```

Authentication is one header:

```
Authorization: Bearer trk_live_...
```

Create the key at [traceaifacescan.app](https://traceaifacescan.app/?utm_source=github&utm_medium=referral&utm_campaign=api-repo) → Panel → API. The bare key without the `Bearer ` prefix is accepted too, because several gateways strip it.

### Matches

Every match carries a `score` from 50 to 100 and a `tier`:

| Tier | Score | Read it as |
|---|---|---|
| `weak` | 50–69 | Similar face. Could be anyone. |
| `possible` | 70–79 | Worth opening the link. |
| `strong` | 80–89 | Very likely the same person. |
| `near_certain` | 90–100 | Same person, or the same source photo. |

For fake-profile checking, act on `strong` and `near_certain` only. A single `weak` hit means nothing.

### Idempotency

`POST /v1/scans` accepts an `Idempotency-Key` header and remembers it for 24 hours. Send the SHA-256 of the image and a retry after a network timeout returns the original scan instead of charging a second credit. The Python example does this.

### Errors

`application/problem+json` with a stable `code` field — `insufficient_credits`, `no_face_detected`, `invalid_image`, `rate_limited`, `unauthenticated`, `not_found`, `validation_failed`, `provider_unavailable`, `server_error`. See [`docs/errors.md`](docs/errors.md).

## Pricing

Credits, bought in packs. One credit per full search, no subscription, credits do not expire.

| Pack | Price | Per search |
|---|---|---|
| 5 credits | $4 | $0.80 |
| 40 credits | $22 | $0.55 |
| 100 credits | $50 | $0.50 |

Plus VAT where it applies. A scan run without credits still returns as a free preview with `locked: true` — you see that a face was found, not where. Prices as of September 2026; check the site for the current list.

Also listed on [RapidAPI](https://rapidapi.com/muratcankuruoffical/api/trace-reverse-face-search-api).

## Privacy

- Uploaded photos are deleted on the schedule shown in each scan's `expires_at`, and `DELETE /v1/scans/{id}` removes a scan and its images immediately.
- No face is stored as a permanent biometric template for later lookup.
- Do not upload photos of other people without a lawful reason for the check.

Full policy: [traceaifacescan.app/privacy](https://traceaifacescan.app/privacy)

## Related reading

- [Reverse face search tool comparison](https://traceaifacescan.app/pimeyes-alternative/?utm_source=github&utm_medium=referral&utm_campaign=api-repo)
- [FaceCheck.ID alternative](https://traceaifacescan.app/facecheck-id-alternative/?utm_source=github&utm_medium=referral&utm_campaign=api-repo)
- [API documentation](https://traceaifacescan.app/ai-face-scan-api/?utm_source=github&utm_medium=referral&utm_campaign=api-repo)
- [Try it without writing code](https://huggingface.co/spaces/muratcankuru/reverse-face-search) — Hugging Face Space
- [On Apify](https://apify.com/muratcankuru/reverse-face-search) — run it as an Actor, no code

## License

The code and documentation in this repository are MIT licensed — copy them into your project freely. The Trace service itself is a paid product governed by its own terms.

Issues and pull requests are welcome, including for bugs in the API itself.
