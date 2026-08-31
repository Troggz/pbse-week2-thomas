#!/usr/bin/env bash
# Step 9 test calls. Run this in a SECOND terminal while `npm run mock` runs.
set -u
BASE=http://127.0.0.1:4010
mkdir -p evidence
KEY=0f7c1b9e-3d21-4a6f-9c05-8e2b7d41a9f0

echo "1) GET /lockers"
curl -s -i "$BASE/lockers" | tee evidence/1-list-lockers.txt | head -1

echo; echo "2) POST /rentals WITH key (expect 201)"
curl -s -i -X POST "$BASE/rentals" \
  -H "Idempotency-Key: $KEY" -H "Content-Type: application/json" \
  -d @body.json | tee evidence/2-rent-ok.txt | head -1

echo; echo "3) POST /rentals WITHOUT key (expect 422 refusal)"
curl -s -i -X POST "$BASE/rentals" \
  -H "Content-Type: application/json" -d @body.json \
  | tee evidence/3-missing-key-422.txt | head -1

echo; echo "Saved replies into evidence/"
