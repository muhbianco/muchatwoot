#!/usr/bin/env bash
# Descobre a tag upstream do Chatwoot sobre a qual o mb/main está (VERSION_CW → vX.Y.Z), busca só
# essa tag e falha se ela não for ancestral do HEAD (o fork tem que continuar "upstream + nossos
# commits"). Imprime a tag. Usado pelos pipelines para o diff de CI e para a tag da imagem.
set -euo pipefail
cd "$(dirname "$0")/../.."

base="v$(tr -d '[:space:]' < VERSION_CW)"
if ! git rev-parse -q --verify "refs/tags/$base" >/dev/null; then
  git fetch -q --depth=1 origin "refs/tags/$base:refs/tags/$base" \
    || git fetch -q --depth=1 https://github.com/chatwoot/chatwoot.git "refs/tags/$base:refs/tags/$base"
fi
if ! git merge-base --is-ancestor "$base" HEAD 2>/dev/null; then
  git fetch -q --deepen=500 origin 2>/dev/null || true
  git merge-base --is-ancestor "$base" HEAD || { echo "HEAD não descende de $base" >&2; exit 1; }
fi
echo "$base"
