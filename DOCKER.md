# Running Paperclip in Docker (macOS)

Guide for running Paperclip in a Docker container, accessible at http://localhost:3100.

All commands assume you are running them from this repository's root directory.

## 1. Install and start Colima

Install Colima (lightweight Docker runtime for macOS):

```bash
brew install colima docker docker-compose
```

Start Colima with enough memory for the build (Vite UI build needs ~6 GB). The `vz`/`virtiofs` options give the best performance for bind mounts on Apple Silicon:

```bash
colima start --cpu 2 --memory 6 --vm-type vz --mount-type virtiofs
```

Then add 2 GB of swap memory to the VM. Open the Colima config:

```bash
colima template
```

Find the `swap` field and set it to `2`:

```yaml
swap: 2
```

Save and restart Colima for the change to take effect:

```bash
colima stop
colima start
```

If Colima is already running with less memory, restart it:

```bash
colima stop
colima start --cpu 2 --memory 6 --vm-type vz --mount-type virtiofs
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
| Data volume | `./paperclip-data` (bind mount) | Persists DB, attachments, encryption keys, agent workspaces |
| Restart policy | `unless-stopped` | Auto-restarts on crash or host reboot |

## Data persistence

All persistent data is stored in `./paperclip-data` on the host, bind-mounted to `/paperclip` inside the container.

- Data lives directly on your Mac filesystem, so it survives Colima restarts, deletions, or reinstalls.
- The directory is browsable in Finder and can be backed up with normal file tools (Time Machine, rsync, etc.).
- `docker compose down` removes the container but the data directory remains untouched.

### Backup

Since data is on the host, you can copy or archive it directly:

```bash
cp -a ./paperclip-data ./paperclip-data-backup
```

Or create a tarball:

```bash
tar czf paperclip-backup.tar.gz -C ./paperclip-data .
```

## Updating

Pull the latest source and rebuild:

```bash
cd paperclip && git pull && cd ..
docker build -t paperclip ./paperclip
docker compose down
docker compose up -d
```

## Troubleshooting

### Build fails with sha256sum check on GitHub CLI keyring

If the build fails with a `sha256sum` mismatch on `githubcli-archive-keyring.gpg`, GitHub has rotated their GPG signing key (they do this periodically). Remove the checksum verification line from `paperclip/Dockerfile`:

```diff
-  && echo "20e0125d..." | sha256sum -c - \
```

The GPG-signed apt repository still validates packages cryptographically, so this is safe to remove.

### Build fails with "JavaScript heap out of memory"

Increase your Colima VM memory:

```bash
colima stop
colima start --cpu 2 --memory 6 --vm-type vz --mount-type virtiofs
```

### "local_trusted mode requires loopback host binding"

Docker containers must bind to `0.0.0.0` for port forwarding to work, which is incompatible with `local_trusted` mode. Use `authenticated` mode instead (already set in the provided `docker-compose.yml`).

### "authenticated mode requires BETTER_AUTH_SECRET"

Add `BETTER_AUTH_SECRET` to your `.env` file:

```bash
echo "BETTER_AUTH_SECRET=$(openssl rand -hex 32)" > .env
```

### EACCES: permission denied on `/paperclip/instances/default/.env`

This happens when files in the data volume are owned by `root` instead of the `node` user (UID 1000). Common cause: running `docker exec` without `-u node`, which defaults to root and creates files with root ownership.

If the container is crash-looping and you can't exec into it, stop it and fix permissions:

```bash
docker compose down
docker run --rm -v "$(pwd)/paperclip-data":/paperclip alpine chown -R 1000:1000 /paperclip
docker compose up -d
```

### Claude Code not recognized by Paperclip

`docker exec` runs as `root` by default, but Paperclip runs as the `node` user. Credentials stored by root are invisible to the Paperclip process. Always exec as `node`:

```bash
docker exec -it -u node paperclip claude login
docker compose restart
```
