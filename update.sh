#!/usr/bin/env sh
set -eu
(set -o 2>/dev/null | grep -q pipefail) && set -o pipefail

retry() {
  max="$1"; shift
  i=1
  while [ "$i" -le "$max" ]; do
    "$@" && return 0
    echo "[warn] attempt $i/$max failed" >&2
    sleep "$i"
    i=$((i + 1))
  done
  return 1
}

VER=0.0.1

. ./config.env
docker compose -f docker-compose.yml down
docker volume rm join_tmkms_data 2>/dev/null || true
sudo rm -rf .inference

[ -e "config.env.backup.$VER" ] || cp config.env "config.env.backup.$VER"
[ -e "docker-compose.yml.backup.$VER" ] || cp docker-compose.yml "docker-compose.yml.backup.$VER"

git checkout .
retry 5 git pull --ff-only

cp config.env.template config.env
sh ./migrate-env.sh "config.env.backup.$VER" config.env "docker-compose.yml.backup.$VER"

retry 5 docker compose -f docker-compose.yml pull

. ./config.env
docker compose -f docker-compose.yml up -d
docker compose -f docker-compose.yml logs -f
