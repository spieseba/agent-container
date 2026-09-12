# Agent Container

A container for coding agents such as Claude Code, Codex, Mistral Vibe and
Antigravity. Built on Fedora and runs with rootless Podman. Supports CPU on
macOS/Fedora and NVIDIA GPU on Fedora. Includes uv, Git, passwordless sudo and config from
[agent-config](https://github.com/spieseba/agent-config).

## Setup

Install Podman and select `podman-compose` as its Compose provider. On macOS,
start a Podman machine with the repository shared into it. Run from this repo:

```bash
podman compose build agent
```

### CPU (macOS/Fedora)

```bash
podman compose up -d agent
podman compose exec agent bash
```

### NVIDIA GPU (Fedora)

For NVIDIA GPU support, install the host driver and
[NVIDIA Container Toolkit](https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/latest/install-guide.html).
Ensure `nvidia-ctk cdi list` lists your GPU, then enable the host-wide SELinux
permission for containers to access mounted X-server device types:

```bash
sudo setsebool -P container_use_xserver_devices on
podman compose stop agent
podman compose --profile gpu up -d --force-recreate agent-gpu
podman compose --profile gpu exec agent-gpu bash
```

Run one service per workspace. The workspace uses private SELinux labels (`:Z`);
when switching services, stop the current one and recreate the destination
with `up -d --force-recreate` so its workspace label is applied.

## Usage

- Projects live in host `./workspace`, mounted at `/home/agent/workspace`.
- Authenticate inside the container with `claude`, `vibe`, `codex` or `agy`.
- `exit` leaves the exec shell; use `exec` again to re-enter.
- Use `stop`/`start` with the same Compose options and service to resume later.
  `down` removes the project's containers. Removal/recreation loses logins and
  runtime installations; workspace files persist. Building alone does not erase logins.
- Install project packages with `sudo dnf install ...`. Node/npm and GPU
  development frameworks/toolchains are not preinstalled.

## Configuration

Edit build arguments in `compose.yaml` for timezone and CLIs. All four CLIs are
enabled; set an `INSTALL_*` argument explicitly to `"false"` to disable it.
Rebuild and recreate to apply image changes. Override `AGENT_CONFIG_REPO` to use
another config repository.

Agents have network access, unrestricted sudo inside the container, and access
to mounted files and container credentials. No host credential directories or
engine socket are mounted. Rootless execution and SELinux confinement do not
guarantee protection against container escapes.

## License

[MIT](https://opensource.org/licenses/MIT)
