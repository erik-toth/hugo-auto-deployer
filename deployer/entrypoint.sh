#!/bin/sh
set -eu

LOG_PREFIX="[entrypoint]"
log() { echo "${LOG_PREFIX} $*"; }

: "${GIT_REPO_URL:?  ERROR: GIT_REPO_URL not set (SSH-Format: git@host:user/repo.git)}"
: "${WEBHOOK_SECRET:? ERROR: WEBHOOK_SECRET not set}"
: "${GIT_BRANCH:=main}"

if [ ! -f /root/.ssh/id_ed25519 ]; then
  echo ""
  echo "  ╔═══════════════════════════╗"
  echo "  ║ ERROR: SSH-Key not found! ║"
  echo "  ╚═══════════════════════════╝"
  echo ""
  exit 1
fi

chmod 600 /root/.ssh/id_ed25519
log "SSH-Key found: /root/.ssh/id_ed25519"

log "Generating hooks.json from template..."
export GIT_BRANCH WEBHOOK_SECRET
envsubst '${WEBHOOK_SECRET} ${GIT_BRANCH}' \
  < /app/hooks.json.tpl \
  > /app/hooks.json

log "hooks.json done."

log "Iniating first deploy..."
/app/deploy.sh || {
  log "WARN: Error during first deploy. Webhook-listener will still start."
}

log "Webhook-Endpoint: POST /hooks/hugo-deploy"

exec webhook \
  -hooks /app/hooks.json \
  -port 9000 \
  -ip 0.0.0.0 \
  -verbose \
  -hotreload
