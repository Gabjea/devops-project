#!/bin/sh
# Smoke test run by Atlantis after every apply: creates a link and follows it.
set -eu

API_URL="$1"

body=$(curl -sf -X POST "$API_URL/links" \
  -H "Content-Type: application/json" \
  -d '{"url":"https://example.com/smoke-test"}')
code=$(echo "$body" | sed -n 's/.*"code": *"\([^"]*\)".*/\1/p')

if [ -z "$code" ]; then
  echo "Smoke test FAILED: could not create a link (response: $body)"
  exit 1
fi

status=$(curl -s -o /dev/null -w '%{http_code}' "$API_URL/links/$code")
if [ "$status" != "302" ]; then
  echo "Smoke test FAILED: expected 302, got $status"
  exit 1
fi

echo "Smoke test passed: created and resolved link $code"