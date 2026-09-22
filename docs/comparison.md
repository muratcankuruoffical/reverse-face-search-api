# Reverse face search APIs compared (September 2026)

Written by the Trace team, so read it with that in mind. The checkable facts are linked; where a competitor is the better fit, it says so.

| | Trace | FaceCheck.ID | PimEyes | Lenso.ai |
|---|---|---|---|---|
| Self-serve API | Yes | Yes | No | Yes |
| Auth | `Authorization: Bearer` | API token | — | API key |
| Billing | Credit packs, card | Credits, crypto only | Subscription, no API | Subscription tiers |
| Credits expire | No | Yes | — | Monthly quota |
| Cost per search | $0.50–$0.80 | Lower at volume | — | Not published |
| Free preview before paying | Yes (`locked: true`) | Limited | Limited | Limited |
| Machine-readable spec | OpenAPI 3.0 | No | — | No |
| Delete an upload on demand | `DELETE /scans/{id}` | — | Account-level | Account-level |

## Where each one actually wins

**FaceCheck.ID** is cheaper per search once you buy in bulk, and its index of scam and dating profiles is strong. The catch for a business is payment: credits are bought with cryptocurrency, and they expire. If your finance team needs a card invoice, that decides it before any technical comparison.

**PimEyes** has the best consumer product of the four — alerts when a new photo of you appears, and a removal-request service. It has no self-serve API, so it is not a build-on-it option; it is a subscription for a person, not a dependency for a product.

**Lenso.ai** does general reverse image search — places, objects, duplicates — with faces as one mode among several. If you need more than faces, it covers ground the others do not. Its API pricing is not published on the site, so budgeting means a sales conversation.

**Trace** is built for the fake-profile case specifically: one photo in, scored profile links out, in three HTTP calls. Credits are bought with a card and do not expire, the spec is OpenAPI so your client is generated rather than hand-written, and a scan run without credits still tells you for free whether anything was found. What it is not: a monitoring service. There are no alerts and no takedown help — if that is what you want, PimEyes is the honest answer.

## Things worth checking yourself before you commit

- **Current prices.** All four change them. Every number here is from September 2026.
- **Your own test photos.** Index coverage differs by region and platform far more than any feature table suggests. Run the same five faces through each and compare the hits, not the marketing.
- **What the terms allow.** Several jurisdictions regulate biometric processing, and every one of these services forbids using it to identify strangers. A "which tool is best" question that ignores the legal basis is the wrong question.

## What none of them can do

Return a person's identity. They return public URLs and a similarity score. Twins, siblings, look-alikes, heavy filters and AI-generated portraits all produce high scores. Treat a match as *this face has been published here before* — which is enough to catch a stolen profile picture, and not enough to accuse anybody of anything.
