# Errors

Every error is `application/problem+json` ([RFC 9457](https://www.rfc-editor.org/rfc/rfc9457)) with a stable `code` field. Branch on `code`, never on the wording of `title` or `detail`.

```json
{
  "type": "https://traceaifacescan.app/problems/insufficient_credits",
  "title": "Insufficient credits",
  "status": 402,
  "code": "insufficient_credits",
  "detail": "This account has no credits left."
}
```

A failed *scan* is not an HTTP error. The request succeeds, and the scan comes back with `status: "failed"` and an `error_code` — most often `no_face_detected`. Handle both places.

| `code` | HTTP | What happened | What to do |
|---|---|---|---|
| `unauthenticated` | 401 | Key missing, malformed, revoked, or the account is suspended | Check the `Authorization` header. All four cases return the same answer on purpose — do not try to tell them apart. |
| `insufficient_credits` | 402 | `reveal` on an empty balance | Top up. The scan stays revealable. |
| `not_found` | 404 | Unknown scan id, or one belonging to another account | Do not retry. |
| `validation_failed` | 422 | Missing `image` field, bad pagination parameters | Fix the request. |
| `invalid_image` | 422 | Not JPEG/PNG/WebP, over 8 MB, or smaller than 200×200 px | Re-encode or ask for another photo. |
| `no_face_detected` | — | No usable face in the photo | Arrives as the scan's `error_code`, not as an HTTP status. Nothing was charged. |
| `rate_limited` | 429 | Per-key limit, or more than 20 failed auth attempts per minute from one IP | Wait for `Retry-After`. Failed auth clears as soon as a valid key is used. |
| `provider_unavailable` | 503 | The search backend is briefly down | Retry with backoff. Resend the same `Idempotency-Key` — it will not double-charge. |
| `server_error` | 500 | Our fault | Retry once; if it persists, open an issue with the timestamp. |
| `409` on `reveal` | 409 | The image was already deleted, so there is nothing left to search | Start a new scan. |

## Retrying safely

Send the SHA-256 of the image bytes as `Idempotency-Key` on `POST /scans`. It is remembered for 24 hours, so a retry after a timeout or a `503` returns the original scan rather than starting and charging a second one.

## What never appears in an error

No key material, no uploaded image, no third-party account data. If you ever see something that looks like private data in a response body, please report it rather than opening a public issue with the payload in it.
