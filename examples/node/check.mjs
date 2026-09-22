// Reverse face search in Node 18+ — no dependencies, no SDK.
//
//   export TRACE_KEY=trk_live_...
//   node examples/node/check.mjs profile.jpg
//
// Get a key at https://traceaifacescan.app -> Panel -> API

import fs from "node:fs";
import crypto from "node:crypto";
import path from "node:path";

const BASE = "https://traceaifacescan.app/api/v1";
const file = process.argv[2] ?? "profile.jpg";

if (!process.env.TRACE_KEY) {
  console.error("Set TRACE_KEY first.");
  process.exit(1);
}

const auth = { Authorization: `Bearer ${process.env.TRACE_KEY}` };
const bytes = fs.readFileSync(file);

const form = new FormData();
form.append("image", new Blob([bytes]), path.basename(file));

// Same photo -> same key: a retry after a timeout never charges twice.
const idem = crypto.createHash("sha256").update(bytes).digest("hex");

let scan = await (
  await fetch(`${BASE}/scans`, {
    method: "POST",
    headers: { ...auth, "Idempotency-Key": idem },
    body: form,
  })
).json();

if (scan.code) {
  console.error(`${scan.code}: ${scan.detail}`);
  process.exit(1);
}

if (scan.locked) {
  console.error(`No credits. Top up, then POST /scans/${scan.id}/reveal.`);
  process.exit(1);
}

while (scan.status === "queued" || scan.status === "running") {
  await new Promise((r) => setTimeout(r, 2000));
  scan = await (await fetch(`${BASE}/scans/${scan.id}`, { headers: auth })).json();
}

if (scan.status === "failed") {
  console.error(`Scan failed: ${scan.error_code}`); // e.g. no_face_detected
  process.exit(1);
}

console.table(
  (scan.matches ?? []).map(({ score, tier, platform, handle, url }) => ({
    score,
    tier,
    platform,
    handle,
    url,
  })),
);
