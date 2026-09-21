#!/usr/bin/env bash
# Deploy do Chatwoot na hel1: StackUpdate do Portainer com o YAML do repo e CHATWOOT_TAG=<tag>
# (dry-run antes). O Env do Portainer (segredos) é preservado pelo script do hel1-ops.
# Rodado pelo Woodpecker (.woodpecker/deploy.yaml, dentro de `hel1-deploy exec`) ou à mão
# (break-glass), na raiz do checkout:
#
#   deploy/hel1/deploy.sh mb-v4.17.1-<sha12>
#   PORTAINER_STACK_UPDATE="python3 /usr/src/hel1-ops/scripts/portainer-stack-update.py" deploy/hel1/deploy.sh <tag>
#
# Migrações rodam no boot do serviço rails (db:chatwoot_prepare), não aqui.
set -euo pipefail

TAG="${1:?usage: deploy.sh <image-tag>}"
[ "$TAG" != latest ] || { echo "refusing :latest; pass the image tag being deployed" >&2; exit 2; }
cd "$(dirname "$0")/../.."
read -r -a UPDATER <<<"${PORTAINER_STACK_UPDATE:-portainer-stack-update}"

"${UPDATER[@]}" --stack chatwoot --yaml deploy/hel1/docker-stack.yml --set-env CHATWOOT_TAG="$TAG" --dry-run
"${UPDATER[@]}" --stack chatwoot --yaml deploy/hel1/docker-stack.yml --set-env CHATWOOT_TAG="$TAG"
