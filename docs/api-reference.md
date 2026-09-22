# API reference

Base URL: `https://traceaifacescan.app/api/v1`
Machine-readable spec: [`../openapi.json`](../openapi.json) · live at [`/openapi.json`](https://traceaifacescan.app/openapi.json)

## Authentication

```
Authorization: Bearer trk_live_...
```

One header, on every request. No OAuth, no session, no CSRF token. Create and revoke keys at [traceaifacescan.app](https://traceaifacescan.app/?utm_source=github&utm_medium=referral&utm_campaign=api-repo) → Panel → API.

The bare key without `Bearer ` is accepted as well, because several API gateways rewrite or strip the scheme. Anything that does not start with `trk_live_` is rejected.

Every authentication failure — missing key, malformed key, revoked key, suspended account — returns the same `401 unauthenticated`. That is deliberate: distinguishing them would let an outsider test whether a key exists.

## Endpoints

### `GET /account`

Credit balance and key info.

```json
{
  "account_id": "acc_...",
  "credits": 15,
  "scan_cost": 1,
  "api_key": { "name": "production", "prefix": "trk_live_ab…", "rate_limit_per_min": 0 }
}
```

`rate_limit_per_min: 0` means no per-minute limit on that key.

### `POST /scans`

`multipart/form-data` with one `image` field. JPEG, PNG or WebP, at most 8 MB, at least 200×200 px, one clearly visible face.

Returns `202` immediately — the search runs in the background.

```json
{
  "id": "01K5T3ZQ8V6X2Y9N4M7P0R1S2T",
  "status": "queued",
  "locked": false,
  "credits_remaining": 14
}
```

There is no `image_url` parameter. Accepting a URL would turn the endpoint into a server-side request forgery tool, so the bytes have to be uploaded.

**`Idempotency-Key` header (optional, strongly recommended).** Remembered for 24 hours. Retrying with the same key returns the original scan instead of starting — and charging — a new one. Use the SHA-256 of the image bytes; a timeout retry then costs nothing.

### `GET /scans/{id}`

Poll every 1–2 seconds. `status` moves `queued` → `running` → `done` or `failed`; `progress` is 0–100.

```json
{
  "id": "01K5T3ZQ8V6X2Y9N4M7P0R1S2T",
  "status": "done",
  "progress": 100,
  "locked": false,
  "match_count": 7,
  "expires_at": "2026-10-22T09:14:00Z",
  "matches": [
    {
      "score": 94,
      "tier": "near_certain",
      "platform": "instagram",
      "handle": "@real_owner",
      "url": "https://instagram.com/real_owner",
      "preview_url": "https://traceaifacescan.app/api/v1/scans/01K5.../previews/0"
    }
  ]
}
```

`preview_url` needs the same `Authorization` header.

`platform` is one of: `instagram`, `x`, `facebook`, `tiktok`, `tinder`, `linkedin`, `youtube`, `threads`, `snapchat`, `pinterest`, `reddit`, `telegram`, `vk`, `github`, `onlyfans`, `web`.

### `POST /scans/{id}/reveal`

Only for a scan that came back with `locked: true`. Spends one credit and runs the full search; poll again afterwards. Already-unlocked scans return `200` unchanged and are not charged. `402 insufficient_credits` when the balance is empty, `409` when the image has already been deleted.

### `DELETE /scans/{id}`

Deletes the scan and its images now, rather than waiting for `expires_at`.

### `GET /scans`

Paginated list, without matches. `page` and `per_page` (max 100).

## Locked scans

Without credits, a scan still runs as a free preview and returns `locked: true`: you learn that the face produced hits, not where. Nothing is charged, and nothing was searched in full. Reveal it when you top up, or ignore it.

Treat `locked` as a normal branch in your code, not an error.

## Match tiers

| Tier | Score | Read it as |
|---|---|---|
| `weak` | 50–69 | Similar face. Could be anyone. |
| `possible` | 70–79 | Worth opening the link. |
| `strong` | 80–89 | Very likely the same person. |
| `near_certain` | 90–100 | Same person, or the same source photo. |

Nothing below 50 is returned. For automated fake-profile flags, use `strong` and above; below that you will bury your reviewers in false positives.

**No score is proof of identity.** Twins, siblings, heavy filters and AI-generated portraits all produce high scores. A high score says *this face has been published here before*, which is exactly what catfish detection needs — and nothing more.

## Limits

No per-minute request limit by default. A per-key limit can be set from the panel; when it is, the response carries `X-RateLimit-Limit`, `X-RateLimit-Remaining` and, on `429`, `Retry-After`.

Failed authentication is throttled by IP: 20 per minute. A valid key clears the counter, so one broken client on a shared address cannot lock out the others.

## Errors

`application/problem+json`, with a stable `code`. See [errors.md](errors.md).
