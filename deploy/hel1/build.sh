#!/usr/bin/env bash
# Generate the overlay COPY list from git and fail if the fork grew outside the allowlist.
# Usage (repo root): deploy/hel1/build.sh
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$ROOT"

BASE="${BASE_TAG:-v4.17.1}"
ALLOWED='^(app/models/channel/api\.rb|app/jobs/webhook_job\.rb|deploy/.+|spec/models/channel/api_spec\.rb|spec/jobs/webhook_job_spec\.rb|\.github/workflows/mb-overlay\.yml)$'

changed="$(git diff --name-only "${BASE}..HEAD")"
if [ -z "$changed" ]; then
  echo "no overlay files vs ${BASE}" >&2
  exit 1
fi

bad="$(printf '%s\n' "$changed" | grep -Ev "$ALLOWED" || true)"
if [ -n "$bad" ]; then
  echo "fork grew outside the overlay allowlist:" >&2
  printf '%s\n' "$bad" >&2
  exit 1
fi

echo "overlay files vs ${BASE}:"
printf '%s\n' "$changed"
