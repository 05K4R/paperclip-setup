# Running Paperclip in Docker

## Context

You currently run Paperclip directly on your host machine via `npx paperclipai onboard`, with an embedded Postgres on port 54329 and data stored in `~/.paperclip/instances/default/`. You want to move to a Docker-based setup for better isolation. You'll start fresh (no data migration needed).

## Dockerfile Security Review

The official Dockerfile (`paperclipai/paperclip`) was reviewed and is clean:

- **4-stage multi-stage build** on `node:lts-trixie-slim` — only production artifacts reach the final image
- **System packages** are standard (git, curl, ripgrep, python3, GitHub CLI). The GitHub CLI apt key is verified with a SHA256 checksum.
- **Global npm packages** installed: `@anthropic-ai/claude-code`, `@openai/codex`, `opencode-ai` — these are the AI CLI tools agents use to execute tasks
- **Runs as non-root** — the entrypoint uses `gosu` to drop to the `node` user before running the app
- **Secure defaults** — `PAPERCLIP_DEPLOYMENT_MODE=authenticated` and `PAPERCLIP_DEPLOYMENT_EXPOSURE=private`
- **Entrypoint** (`scripts/docker-entrypoint.sh`) only adjusts the `node` user UID/GID to match host user, then `exec gosu node "$@"` — nothing unexpected

## Data Persistence — Named Docker Volume

A **named volume** (`paperclip-data`) is used for all persistent data:

- **What it stores:** Postgres database files, uploaded attachments, encryption keys, agent workspaces, instance config — all under `/paperclip` in the container
- **Where it lives on host:** Managed by Docker internally (on macOS, inside the Docker Desktop VM at `/var/lib/docker/volumes/paperclip-data/_data/`). Not directly browsable from Finder.
- **Isolation:** The container **cannot** access your host filesystem. It can only see its own image layers and the `/paperclip` mount point. Your home directory, other projects, and system files are invisible to it.
- **Lifecycle:** The volume persists independently of the container. Running `docker compose down` stops and removes the container but keeps the volume. Only `docker volume rm paperclip-data` would delete it.
- **Backup:** Use `docker cp paperclip:/paperclip ./backup` or `docker run --rm -v paperclip-data:/data -v $(pwd):/backup alpine tar czf /backup/paperclip-backup.tar.gz -C /data .`

## Approach

### Step 1: Build the Docker image

```bash
git clone https://github.com/paperclipai/paperclip.git ~/Development/paperclip-docker
cd ~/Development/paperclip-docker
docker build -t paperclip .
```

### Step 2: Create a `docker-compose.yml`

Create `~/Development/paperclip-docker/docker-compose.yml`:

```yaml
services:
  paperclip:
    image: paperclip
    container_name: paperclip
    restart: unless-stopped
    ports:
      - "3100:3100"
    environment:
      - HOST=0.0.0.0
      - PORT=3100
      - PAPERCLIP_HOME=/paperclip
      - PAPERCLIP_DEPLOYMENT_MODE=authenticated
      - SERVE_UI=true
      - ANTHROPIC_API_KEY=${ANTHROPIC_API_KEY}
      - BETTER_AUTH_SECRET=${BETTER_AUTH_SECRET}
      # - OPENAI_API_KEY=${OPENAI_API_KEY}
    volumes:
      - paperclip-data:/paperclip

volumes:
  paperclip-data:
```

### Step 3: Create a `.env` file for secrets

Create `~/Development/paperclip-docker/.env`:

```
ANTHROPIC_API_KEY=sk-ant-...
BETTER_AUTH_SECRET=<random-hex-string>   # generate with: openssl rand -hex 32
# OPENAI_API_KEY=sk-...
```

### Step 4: Run it

```bash
cd ~/Development/paperclip-docker
docker compose up -d
```

Access the UI at `http://localhost:3100`. Run through the onboarding flow in the browser.

### Step 5: Stop your host-based Paperclip instance

Once the Docker setup is working, stop and optionally remove the host install to avoid port conflicts and confusion. The host data lives at `~/.paperclip/instances/default/` and can be kept as a backup or deleted.

## Key details

| Concern | Detail |
|---------|--------|
| **Port** | 3100 (same as your current setup) |
| **Data persistence** | Named Docker volume `paperclip-data` mounted at `/paperclip` — isolated from host filesystem |
| **Database** | Embedded Postgres runs inside the container (no external DB needed) |
| **API keys** | Passed via environment variables / `.env` file |
| **Deployment mode** | `authenticated` (required in Docker since `local_trusted` only allows loopback binding, but containers need `0.0.0.0`) |
| **Updates** | `git pull && docker build -t paperclip . && docker compose up -d` |
| **Volume backup** | `docker cp paperclip:/paperclip ./backup` |

## Verification

1. Run `docker compose up -d` and check logs with `docker compose logs -f`
2. Open `http://localhost:3100` in a browser
3. Complete the onboarding flow
4. Restore agent instructions from your git repo if desired:
   ```bash
   docker cp ~/Development/paperclip/companies/ paperclip:/paperclip/instances/default/companies/
   ```

## Notes

- There is no official pre-built image on Docker Hub — you need to build from source. There are community mirrors (`reeoss/paperclipai-paperclip`) but using the official repo is safer.
- Hostinger and Zeabur offer one-click Paperclip VPS deployments if you want a hosted option later.
- Your existing `~/Development/paperclip` backup repo remains useful for version-controlling agent instructions regardless of how you run Paperclip.
