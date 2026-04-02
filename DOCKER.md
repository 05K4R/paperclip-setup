# Running Paperclip in Docker (macOS)

Guide for running Paperclip in a Docker container, accessible at http://localhost:3100.

All commands assume you are running them from this repository's root directory.

## 1. Install and start Colima

Install Colima (lightweight Docker runtime for macOS):

```bash
brew install colima docker docker-compose
```

Start Colima with enough memory for the build (Vite UI build needs ~6 GB):

```bash
colima start --cpu 2 --memory 6
```

If Colima is already running with less memory, restart it:

```bash
colima stop
colima start --cpu 2 --memory 6
```

## 2. Clone the Paperclip source

Clone the official Paperclip repository into this directory (it is gitignored):

```bash
git clone https://github.com/paperclipai/paperclip.git
```

## 3. Build the Docker image

```bash
docker build -t paperclip ./paperclip
```

This is a multi-stage build that compiles the UI, plugin SDK, and server. It also pre-installs Claude Code CLI, Codex CLI, and opencode-ai for agent task execution. Expect this to take a while on first build.

## 4. Configure secrets

Create a `.env` file in this directory:

```bash
echo "BETTER_AUTH_SECRET=$(openssl rand -hex 32)" > .env
```

If using API key auth instead of a Claude Code subscription, also add:

```
ANTHROPIC_API_KEY=sk-ant-...
OPENAI_API_KEY=sk-...
```

## 5. Start the container

```bash
docker compose up -d
```

Check that it started successfully:

```bash
docker compose logs -f
```

(Press Ctrl+C to stop following logs.)

## 6. Authenticate Claude Code (subscription users)

If you use a Claude Code subscription rather than API keys:

```bash
docker exec -it paperclip claude login
```

This opens an OAuth flow in your browser.

## 7. Access Paperclip

Open http://localhost:3100 and complete the onboarding/sign-up flow.

## Configuration

The `docker-compose.yml` is set up with:

| Setting | Value | Notes |
|---------|-------|-------|
| Port | 3100 | Same as default Paperclip |
| Deployment mode | `authenticated` | Required in Docker (`local_trusted` only allows loopback binding, but containers need `0.0.0.0`) |
| Data volume | `paperclip-data` (named volume) | Persists DB, attachments, encryption keys, agent workspaces |
| Restart policy | `unless-stopped` | Auto-restarts on crash or host reboot |

## Data persistence

All persistent data is stored in a named Docker volume (`paperclip-data`) mounted at `/paperclip` inside the container.

- The container cannot access the host filesystem. It can only see its own image layers and the `/paperclip` mount point.
- The volume persists independently of the container. `docker compose down` removes the container but keeps the volume. Only `docker volume rm paperclip-docker-setup_paperclip-data` deletes it.
- On macOS, the volume lives inside the Colima VM and is not directly browsable from Finder.

### Backup

Copy data out of the container:

```bash
docker cp paperclip:/paperclip ./backup
```

Or create a tarball:

```bash
docker run --rm \
  -v paperclip-docker-setup_paperclip-data:/data \
  -v "$(pwd)":/backup \
  alpine tar czf /backup/paperclip-backup.tar.gz -C /data .
```

## Updating

Pull the latest source and rebuild:

```bash
cd paperclip && git pull && cd ..
docker build -t paperclip ./paperclip
docker compose up -d
```

## Troubleshooting

### Build fails with "JavaScript heap out of memory"

Increase your Colima VM memory:

```bash
colima stop
colima start --cpu 2 --memory 6
```

### "local_trusted mode requires loopback host binding"

Docker containers must bind to `0.0.0.0` for port forwarding to work, which is incompatible with `local_trusted` mode. Use `authenticated` mode instead (already set in the provided `docker-compose.yml`).

### "authenticated mode requires BETTER_AUTH_SECRET"

Add `BETTER_AUTH_SECRET` to your `.env` file:

```bash
echo "BETTER_AUTH_SECRET=$(openssl rand -hex 32)" > .env
```
