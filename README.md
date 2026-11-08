# Hardened Syncthing Container

[![CI](https://github.com/underhax/syncthing-docker/actions/workflows/ci.yml/badge.svg)](https://github.com/underhax/syncthing-docker/actions/workflows/ci.yml)
[![GitHub last commit](https://img.shields.io/github/last-commit/underhax/syncthing-docker)](https://github.com/underhax/syncthing-docker/commits/main)
[![GitHub issues](https://img.shields.io/github/issues/underhax/syncthing-docker)](https://github.com/underhax/syncthing-docker/issues)
[![GitHub repo size](https://img.shields.io/github/repo-size/underhax/syncthing-docker)](https://github.com/underhax/syncthing-docker)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

Hardened scratch container distribution for [Syncthing](https://github.com/syncthing/syncthing) with an embedded static Go health probe.

## Architecture & Security Model

- Scratch base image containing only the Syncthing binary, CA certificates, and health probe.
- Read-only root filesystem.
- All Linux capabilities dropped.
- Privilege escalation disabled.
- Non-root execution using host UID and GID.
- Isolated IPC namespace.
- Strict CPU, memory, and PID limits.
- Ephemeral storage restricted to memory-backed tmpfs with noexec, nosuid, and nodev.
- Health monitoring handled by a static Go binary without external dependencies.

---

<details>
<summary><strong>Directory Structure</strong></summary>

Production directory layout on the host (`/home/syncthing`):

```text
├── docker-compose.yaml                     # Production deployment manifest
├── .env                                    # Host infrastructure configuration
├── config/                                 # Persistent Syncthing configuration and index database
└── data/                                   # Synced data storage directory
```

</details>

---

<details>
<summary><strong>Deployment &amp; Setup</strong></summary>

### Prerequisites

* **Docker Engine & Compose:** Ensure Docker Engine and the Docker Compose plugin are installed on the host. Follow the official installation guide for [Ubuntu](https://docs.docker.com/engine/install/ubuntu/#install-using-the-repository).

### 1. Create a Dedicated System User

Choose a dedicated, unprivileged numeric ID unique to this service on your host and verify that it is not in use:

```bash
APP_UID=<CHOSEN_UID>

getent passwd ${APP_UID}
getent group ${APP_UID}
```

Create an unprivileged system account with a matching user-group (`-U`) and disabled login shell:

```bash
sudo useradd -M -d /home/syncthing -s /usr/sbin/nologin -u ${APP_UID} -U syncthing
```

### 2. Create Directory Layout & Assign Ownership

Create the base directory and persistent storage:

```bash
sudo mkdir -p /home/syncthing/{config,data}
sudo chown root:syncthing /home/syncthing
sudo chmod 0750 /home/syncthing

sudo chown syncthing:syncthing /home/syncthing/{config,data}
sudo chmod 0700 /home/syncthing/{config,data}
```

### 3. Deploy Project Files

Download the production manifests into `/home/syncthing`:

```bash
REPO="https://raw.githubusercontent.com/underhax/syncthing-docker/main"

sudo curl -fsSL ${REPO}/docker-compose.yaml -o /home/syncthing/docker-compose.yaml
sudo curl -fsSL ${REPO}/.env.example -o /home/syncthing/.env

sudo chown root:root /home/syncthing/{docker-compose.yaml,.env}
sudo chmod 0600 /home/syncthing/{docker-compose.yaml,.env}
```

### 4. Configure Host Environment Settings

Update `/home/syncthing/.env` with your assigned UID/GID and network settings:

```bash
sed -i "s/^APP_UID=.*/APP_UID=${APP_UID}/" /home/syncthing/.env
sed -i "s/^APP_GID=.*/APP_GID=${APP_UID}/" /home/syncthing/.env
```

Review port bindings and WireGuard/host IP mappings in `.env` as required.

### 5. Start the Stack

Pull the latest release and start the service in detached mode:

```bash
sudo docker compose -f /home/syncthing/docker-compose.yaml pull
sudo docker compose -f /home/syncthing/docker-compose.yaml up -d
```

</details>

---

<details>
<summary><strong>Operation &amp; Maintenance</strong></summary>

### Verifying Service Health

Check container status and resource consumption:

```bash
sudo docker compose -f /home/syncthing/docker-compose.yaml ps
sudo docker stats --no-stream syncthing
```

Inspect healthcheck status directly:

```bash
sudo docker inspect --format='{{json .State.Health}}' syncthing
```

### Inspecting Runtime Logs

Follow service logs in real time:

```bash
sudo docker compose -f /home/syncthing/docker-compose.yaml logs -f
```

### Tearing Down the Stack

Stop and remove the container:

```bash
sudo docker compose -f /home/syncthing/docker-compose.yaml down
```

</details>

---

<details>
<summary><strong>Development</strong></summary>

For local compilation, testing, static analysis, and CI/CD details, see **[DEVELOPMENT.md](DEVELOPMENT.md)**.

</details>

---

<details>
<summary><strong>License &amp; Attribution</strong></summary>

## License & Attribution

This repository and deployment architecture are licensed under the [MIT License](LICENSE).

**Syncthing License & Ownership:** Syncthing is open-source software licensed under the [Mozilla Public License 2.0](https://github.com/syncthing/syncthing/blob/main/LICENSE) and developed by [The Syncthing Authors](https://github.com/syncthing/syncthing).

</details>
