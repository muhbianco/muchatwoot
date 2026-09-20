# Overlay image for hel1. Do not use docker/Dockerfile upstream (full Rails/Vue compile).
# Build from the repository root:
#   docker build -f deploy/hel1/Dockerfile -t chatwoot:latest .
FROM chatwoot/chatwoot:v4.17.1

COPY app/models/channel/api.rb /app/app/models/channel/api.rb
COPY app/jobs/webhook_job.rb /app/app/jobs/webhook_job.rb
