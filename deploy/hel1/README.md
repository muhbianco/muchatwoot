# Chatwoot overlay — hel1

Fonte: `muchatwoot@mb/main` sobre `chatwoot/chatwoot:v4.17.1`.

Dois patches só:

- `app/models/channel/api.rb` — `webhook_url` `"null"` / `"undefined"` vira `nil`
- `app/jobs/webhook_job.rb` — URL sem `http(s)://` não dispara

Branding (`LOGO*`) fica no Super Admin (URL no MinIO). Sem assets nesta imagem.

## Build na VPS

```bash
cd /usr/src/muchatwoot
git pull --ff-only
docker build -f deploy/hel1/Dockerfile -t chatwoot:latest .
docker tag chatwoot:latest muhrilobianco/chatwoot:latest
docker tag chatwoot:latest muhrilobianco/chatwoot:mb-v4.17.1-1
docker push muhrilobianco/chatwoot:latest
docker push muhrilobianco/chatwoot:mb-v4.17.1-1
```

Stack: `deploy/hel1/docker-stack.yml` (mesmas `${VAR}` da stack `chatwoot` no Portainer).

Portão local: `deploy/hel1/build.sh` (falha se o diff vs `v4.17.1` sair do allowlist).
