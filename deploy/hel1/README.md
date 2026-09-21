# Chatwoot — hel1

Fonte única: `muchatwoot@mb/main` = tag upstream (`VERSION_CW`, hoje `v4.17.1`) + nossos commits.
O antigo repo `muh-chatwoot` (overlay de arquivos sobre a imagem oficial) foi absorvido aqui.

Customizações atuais:

- `app/models/channel/api.rb` — `webhook_url` `"null"` / `"undefined"` vira `nil`
- `app/jobs/webhook_job.rb` — URL sem `http(s)://` não dispara
- `public/brand-assets/logo{,_dark,_thumbnail}.svg` — logos MuhBianco (padrão das telas; o Super
  Admin ainda pode apontar `LOGO*` para outra URL)

Qualquer outra mudança no código (Ruby, Vue, gems, migrations, `enterprise/`) entra na imagem sem
mexer em pipeline: o build é do fork inteiro.

## Deploy = push no `mb/main`

Woodpecker (`ci.muhbianco.com.br`):

1. `.woodpecker/ci.yaml` — `base-tag.sh` confere que o HEAD descende da tag upstream; `ci-ruby.sh`
   roda rubocop nos `.rb` alterados e rspec dos specs afetados (Postgres pgvector + Redis de serviço);
   `ci-frontend.sh` roda eslint/vitest relacionados quando `app/javascript/**` muda.
2. `.woodpecker/deploy.yaml` — `docker build -f docker/Dockerfile` (Dockerfile do upstream, com
   `ENV CW_EDITION="ee"` como no publish oficial) → `muhrilobianco/chatwoot:mb-<base>-<sha12>` (+ `:latest`)
   → `deploy.sh <tag>` (StackUpdate com o `docker-stack.yml` deste diretório e `CHATWOOT_TAG`, Env do
   Portainer preservado) → espera `chatwoot_rails` e `chatwoot_sidekiq` na tag → smoke em `/api`.

Migrações: o serviço `rails` roda `db:chatwoot_prepare` antes de subir o servidor (idempotente). O
healthcheck com `start_period` segura o start-first até a task nova responder.

Rollback: `git revert` + push, ou na hel1
`PORTAINER_STACK_UPDATE="python3 /usr/src/hel1-ops/scripts/portainer-stack-update.py" deploy/hel1/deploy.sh <tag anterior>`
(migrações do upstream não têm down garantido: rollback de versão upstream exige cuidado).

## Atualizar a versão upstream

1. `git fetch upstream --tags` e `git merge vX.Y.Z` no `mb/main` (merge, não rebase: sem force-push,
   e a guarda de ordem do deploy continua vendo o commit implantado como ancestral).
2. Conferir que `VERSION_CW` = `X.Y.Z` e resolver conflitos nos arquivos customizados.
3. Push no `mb/main`: o build e as migrações da versão nova rodam sozinhos.
