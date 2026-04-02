#!/bin/sh
set -euo pipefail

REPO_DIR="/app/repo"
PUBLIC_DIR="/public"
SSH_KEY="/root/.ssh/id_ed25519"
LOG_PREFIX="[hugo-deployer]"

log()  { echo "${LOG_PREFIX} $(date '+%Y-%m-%d %H:%M:%S') INFO  $*"; }
warn() { echo "${LOG_PREFIX} $(date '+%Y-%m-%d %H:%M:%S') WARN  $*" >&2; }
err()  { echo "${LOG_PREFIX} $(date '+%Y-%m-%d %H:%M:%S') ERROR $*" >&2; exit 1; }

: "${GIT_REPO_URL:?GIT_REPO_URL must be set (SSH-Format: git@host:user/repo.git)}"
: "${GIT_BRANCH:=main}"

[ -f "$SSH_KEY" ] || err "SSH-Key not found: $SSH_KEY."

chmod 600 "$SSH_KEY"

if [ -f /root/.ssh/known_hosts ]; then
  log "known_hosts found"
  export GIT_SSH_COMMAND="ssh -i ${SSH_KEY} -o StrictHostKeyChecking=yes -o BatchMode=yes"
else
  warn "No known_hosts"
  export GIT_SSH_COMMAND="ssh -i ${SSH_KEY} -o StrictHostKeyChecking=accept-new -o BatchMode=yes"
fi

log "GIT_SSH_COMMAND: $GIT_SSH_COMMAND"

if [ -d "${REPO_DIR}/.git" ]; then
  log "Repository already cloned... fetching instead"
  cd "$REPO_DIR"

  git fetch origin "${GIT_BRANCH}"
  git checkout "${GIT_BRANCH}"
  git reset --hard "origin/${GIT_BRANCH}"
  git submodule update --init --recursive

  log "Sync done. Current commit: $(git log -1 --oneline)"
else
  log "Cloning ${GIT_REPO_URL} (Branch: ${GIT_BRANCH})..."
  git clone \
    --branch "${GIT_BRANCH}" \
    --depth 1 \
    --recurse-submodules \
    "${GIT_REPO_URL}" \
    "${REPO_DIR}"

  log "Clone done. Current commit: $(git -C "${REPO_DIR}" log -1 --oneline)"
fi

cd "$REPO_DIR"

log "Starting hugo-build..."

mkdir -p data

HASH=$(git rev-parse HEAD)
AUTHOR=$(git log -1 --format="%an")
DATE=$(git log -1 --format="%ad" --date=format:"%d.%m.%Y %H:%M:%S")
SUBJECT=$(git log -1 --format="%s")

cat <<EOF > data/build_info.json
{
  "hash": "$HASH",
  "author": "$AUTHOR",
  "date": "$DATE",
  "subject": "$SUBJECT"
}
EOF

log "Build info generated: ${HASH}"


# shellcheck disable=SC2086
hugo \
  --destination "${PUBLIC_DIR}" \
  --cleanDestinationDir \
  ${HUGO_EXTRA_FLAGS:-}

log "Hugo-Build done."
log "Stored in ${PUBLIC_DIR}:"
find "$PUBLIC_DIR" -maxdepth 2 -type f | head -30
