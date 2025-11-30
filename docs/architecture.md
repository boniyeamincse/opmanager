# OpManager Docker Architecture

## High-Level Overview
```
┌─────────────────────┐    ┌─────────────────────┐
│   Host Machine      │    │   External Tools    │
│  (Linux w/ Rootless │◄──►│ • Prometheus       │
│      Docker)        │    │ • Grafana           │
└──────────┬──────────┘    │ • Slack/Email       │
           │               └─────────────────────┘
           │
           ▼
┌─────────────────────┐
│ docker-compose.yml  │
│   ├─ opmanager svc  │
│   └─ Volumes (data) │
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│   Container         │
│ ┌─────────────────┐ │ Ports: 8060/8443
│ │   CentOS 9      │ │
│ │ ├─ OpenJDK 17   │ │
│ │ ├─ OpManager    │ │
│ │ │  (non-root)   │ │
│ │ └─ MySQL DB     │ │
│ └─────────────────┘ │
└─────────────────────┘
```

## Components

### 1. **Host Layer**
- **Rootless Docker**: Runs daemon as non-root user (systemd-user).
- **Docker Compose v2**: Orchestrates single-container deployment.
- **Persistent Volumes** (bind-mounted or named):
  | Volume | Path | Purpose |
  |--------|------|---------|
  | `opmanager_mysql` | `/opt/ManageEngine/OpManager/Mysql` | Device data, configs |
  | `opmanager_conf` | `/opt/ManageEngine/OpManager/conf` | Settings, credentials |
  | `opmanager_logs` | `/opt/ManageEngine/OpManager/logs` | Audit trails, errors |
  | `opmanager_pgbackup` | `/opt/ManageEngine/OpManager/pgbackup` | Automated backups |

### 2. **Container Layer**
- **Base**: [`centos:9`](Dockerfile:L2)
- **Runtime User**: `opmanager` (UID 1000, no sudo).
- **Installer**: Silent mode (`-q -i console`), auto-chowned.
- **JVM**: Tunable via `JAVA_OPTS=-Xms2g -Xmx4g`.
- **Entrypoint**: `startOpManager.sh && tail -f /dev/null`.
- **Exposed Ports**:
  | Port | Protocol | Use |
  |------|----------|-----|
  | 8060 | HTTP | Web UI (setup/dashboard) |
  | 8443 | HTTPS | Secure access |

### 3. **Data Flow**
1. **Monitoring**: SNMP/ICMP → OpManager → MySQL.
2. **Alerts**: Thresholds → Email/Slack/Traps.
3. **Health**: Curl `/` → Docker healthcheck.
4. **Persistence**: Volumes survive `docker compose down`.

### 4. **Scalability**
- Single-node: Fine for <1000 devices.
- Multi-node: Use OpManager Central/Probe architecture (custom compose).
- Kubernetes: Helm chart or `docker compose` → K8s manifests.

### 5. **Security Model**
- **Non-root**: Least privilege.
- **Volumes**: User-owned (chown on host).
- **Network**: Host-only ports; proxy for prod.
- **Secrets**: Extend with Docker secrets/env files.

See [`administration.md`](administration.md) for ops, [`userguide.md`](userguide.md) for usage.