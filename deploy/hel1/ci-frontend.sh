#!/usr/bin/env sh
# CI front do fork: eslint nos .js/.vue alterados vs a tag upstream base e vitest só dos testes
# relacionados às mudanças (vitest --changed <base>). Roda em node:24-alpine.
set -eu
cd "$(dirname "$0")/../.."

[ -s .ci/base ] && [ -f .ci/changed ] || { echo ".ci/base ou .ci/changed ausente (step base não rodou?)" >&2; exit 1; }
apk add --no-cache git >/dev/null
# O workspace pode ter outro dono que o usuário do container; o vitest --changed usa git.
git config --global --add safe.directory "$PWD"
corepack enable
pnpm install --frozen-lockfile

base=$(cat .ci/base)
files=$(grep -E '^app/.*\.(js|vue)$' .ci/changed | while read -r f; do [ -f "$f" ] && echo "$f"; done || true)
if [ -n "$files" ]; then
  # shellcheck disable=SC2086
  pnpm exec eslint $files
fi
TZ=UTC pnpm exec vitest run --no-coverage --changed "$base" --passWithNoTests
