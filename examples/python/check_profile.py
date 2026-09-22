import os
import sys
import time
import hashlib
import requests

BASE = "https://traceaifacescan.app/api/v1"
HEADERS = {"Authorization": f"Bearer {os.environ['TRACE_KEY']}"}


def start_scan(path: str) -> dict:
    data = open(path, "rb").read()
    # Same photo -> same key: a retry after a timeout never charges twice.
    idem = hashlib.sha256(data).hexdigest()
    r = requests.post(
        f"{BASE}/scans",
        headers={**HEADERS, "Idempotency-Key": idem},
        files={"image": (os.path.basename(path), data)},
        timeout=60,
    )
    r.raise_for_status()
    return r.json()


def wait(scan_id: str) -> dict:
    while True:
        scan = requests.get(f"{BASE}/scans/{scan_id}", headers=HEADERS, timeout=30).json()
        if scan["status"] in ("done", "failed"):
            return scan
        time.sleep(2)


def check(path: str, claimed_handle: str | None = None) -> None:
    scan = start_scan(path)

    if scan["locked"]:
        sys.exit(f"No credits: the scan is locked. Top up, then POST /scans/{scan['id']}/reveal.")

    scan = wait(scan["id"])
    if scan["status"] == "failed":
        sys.exit(f"Scan failed: {scan['error_code']}")  # e.g. no_face_detected

    strong = [m for m in scan["matches"] if m["tier"] in ("strong", "near_certain")]
    for m in strong:
        print(f"{m['score']:>3}  {m['platform']:<10} {m['handle'] or '-':<24} {m['url']}")

    if claimed_handle:
        others = [m for m in strong if m["handle"] and m["handle"].lstrip("@").lower() != claimed_handle.lower()]
        if others:
            print(f"\n⚠ Same face appears under {len(others)} other account(s). Review manually.")


if __name__ == "__main__":
    check(sys.argv[1], sys.argv[2] if len(sys.argv) > 2 else None)
