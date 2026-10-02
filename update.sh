#!/usr/bin/env bash
# Update the Dockerized Paperclip to a specific release tag.
#
# Usage: ./update.sh [tag]     (prompts for the tag if not given)
set -euo pipefail

cd "$(dirname "$0")"

if ! docker info >/dev/null 2>&1; then
  echo "Docker isn't reachable. Is Colima running? (colima start)" >&2
  exit 1
fi

echo "==> Fetching release tags"
git -C paperclip fetch --tags --force origin

current=$(git -C paperclip describe --tags --exact-match --match 'v*' HEAD 2>/dev/null || echo "unknown")
echo
echo "Current version: $current"
echo "Latest stable releases:"
git -C paperclip tag -l 'v*' --sort=-v:refname | grep -v -- '-' | head -5 | sed 's/^/  /'
echo

tag=${1:-}
if [ -z "$tag" ]; then
  read -r -p "Version tag to install: " tag
fi
tag=$(echo "$tag" | tr -d '[:space:]')

if ! git -C paperclip rev-parse -q --verify "refs/tags/$tag" >/dev/null; then
  echo "Tag '$tag' not found." >&2
  exit 1
fi

if [ "$current" != "unknown" ] && [ "$current" != "$tag" ]; then
  older=$(printf '%s\n%s\n' "$current" "$tag" | sort -V | head -1)
  if [ "$older" = "$tag" ]; then
    echo "WARNING: $tag is older than $current. Newer versions may have applied"
    echo "database migrations that older releases don't understand."
    read -r -p "Downgrade anyway? [y/N] " ans
    [[ "$ans" =~ ^[Yy]$ ]] || exit 1
  fi
fi

read -r -p "Back up ./paperclip-data first? (can take a while) [y/N] " ans
if [[ "$ans" =~ ^[Yy]$ ]]; then
  backup="paperclip-backup-$(date +%Y%m%d-%H%M%S).tar.gz"
  echo "==> Backing up to $backup"
  tar czf "$backup" -C ./paperclip-data .
fi

echo "==> Checking out $tag"
git -C paperclip checkout -q "$tag"

echo "==> Building image (this takes a while)"
# A new epoch busts the build cache for the CLI tools layer so Claude Code,
# Codex etc. are reinstalled at their latest versions (at most once per day).
docker build --build-arg CLI_TOOLS_CACHE_EPOCH="$(date +%Y%m%d)" -t paperclip ./paperclip

echo "==> Restarting container"
docker compose down
docker compose up -d

echo "==> Waiting for http://localhost:3100"
for _ in $(seq 1 60); do
  if curl -fs -m 3 -o /dev/null http://localhost:3100; then
    echo "Paperclip $tag is up at http://localhost:3100"
    exit 0
  fi
  sleep 5
done

echo "Paperclip didn't respond within 5 minutes. Check: docker compose logs -f" >&2
exit 1
