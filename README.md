# Agent Container

A container for coding agents such as Claude Code, Codex, Mistral Vibe and
Antigravity. Built on Fedora and runs with rootless Podman. Supports CPU on
macOS/Fedora hosts and NVIDIA GPU on Fedora hosts. Includes uv, Git, passwordless sudo 
and my personal [agent-config](https://github.com/spieseba/agent-config).

## Setup

Install Podman with `podman-compose` as its Compose provider. On macOS,
start a Podman machine with the repository shared into it. From this repo,
choose one of the following to build, start and enter a new container.

### CPU (macOS/Fedora)

```bash
podman compose build agent
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
podman compose --profile gpu build agent-gpu
podman compose --profile gpu up -d agent-gpu
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

Edit build arguments in `compose.yaml` for timezone, CLIs and personal config. For instance:
- By default, all four CLIs are enabled; set their `INSTALL_*` arguments to `"false"` to disable them.
- Set `INSTALL_AGENT_CONFIG` to `"false"` to skip cloning and installing personal agent config.
Rebuild and recreate to apply image changes. Override `AGENT_CONFIG_REPO` to use
another config repository.

## Note of caution 

Agents have network access, unrestricted sudo inside the container, and access
to mounted files and container credentials. No host credential directories or
engine socket are mounted. Rootless execution and SELinux confinement do not
guarantee protection against container escapes.

## License

[MIT](https://opensource.org/licenses/MIT)
