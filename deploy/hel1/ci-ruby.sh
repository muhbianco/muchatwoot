#!/usr/bin/env bash
# CI Ruby do fork: rubocop nos .rb alterados e rspec dos specs afetados, comparando com a tag
# upstream base (.ci/base, escrita por base-tag.sh). Espera Postgres (pgvector) em $POSTGRES_HOST
# e Redis em $REDIS_URL. Sem mudança Ruby vs a base, não instala nada.
set -euo pipefail
cd "$(dirname "$0")/../.."

# Lista de arquivos vem do step `base` (git diff vs a tag); ausente = falha, nunca "nada mudou".
[ -s .ci/base ] && [ -f .ci/changed ] || { echo ".ci/base ou .ci/changed ausente (step base não rodou?)" >&2; exit 1; }
base=$(cat .ci/base)
mapfile -t changed < .ci/changed

specs=() rbfiles=()
add_spec() { local s=$1 x; [ -f "$s" ] || return 0; for x in "${specs[@]}"; do [ "$x" = "$s" ] && return 0; done; specs+=("$s"); }
for f in "${changed[@]}"; do
  [ -f "$f" ] || continue
  case "$f" in
    *.rb) rbfiles+=("$f") ;;
  esac
  case "$f" in
    spec/*_spec.rb | enterprise/spec/*_spec.rb) add_spec "$f" ;;
    app/*.rb) s="spec/${f#app/}"; add_spec "${s%.rb}_spec.rb" ;;
    lib/*.rb) s="spec/lib/${f#lib/}"; add_spec "${s%.rb}_spec.rb" ;;
    enterprise/app/*.rb) s="spec/enterprise/${f#enterprise/app/}"; add_spec "${s%.rb}_spec.rb" ;;
  esac
done

echo "base: $base"
echo "rubocop: ${rbfiles[*]:-(nenhum)}"
echo "rspec:   ${specs[*]:-(nenhum)}"
if [ ${#rbfiles[@]} -eq 0 ] && [ ${#specs[@]} -eq 0 ]; then
  echo "nada de Ruby mudou vs $base"
  exit 0
fi

bundle config set --local without development
bundle install -j4 --quiet
if [ ${#rbfiles[@]} -gt 0 ]; then bundle exec rubocop --force-exclusion "${rbfiles[@]}"; fi

if [ ${#specs[@]} -gt 0 ]; then
  # O boot do Rails (ExecJS) precisa de um runtime JS; o CI do upstream também instala Node.
  if ! command -v node >/dev/null; then
    apt-get update -qq && apt-get install -y -qq --no-install-recommends nodejs >/dev/null
  fi
  # A imagem do Postgres só abre TCP depois do init (o init roda sem listen_addresses).
  for _ in $(seq 1 60); do (exec 3<>"/dev/tcp/${POSTGRES_HOST}/5432") 2>/dev/null && break; sleep 2; done
  bundle exec rake db:create db:schema:load
  bundle exec rspec --format progress "${specs[@]}"
fi
