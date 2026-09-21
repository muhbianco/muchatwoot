#!/usr/bin/env sh
# CI front do fork: eslint nos .js/.vue alterados vs a tag upstream base e vitest só dos testes
# relacionados às mudanças (vitest --changed <base>). Roda em node:24-alpine.
set -eu
cd "$(dirname "$0")/../.."

apk add --no-cache git >/dev/null
corepack enable
pnpm install --frozen-lockfile

base=$(cat .ci/base)
files=$(git diff --name-only "$base" HEAD | grep -E '^app/.*\.(js|vue)$' | while read -r f; do [ -f "$f" ] && echo "$f"; done || true)
if [ -n "$files" ]; then
  # shellcheck disable=SC2086
  pnpm exec eslint $files
fi
TZ=UTC pnpm exec vitest run --no-coverage --changed "$base" --passWithNoTests
