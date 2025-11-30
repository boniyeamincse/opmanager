# ManageEngine OpManager Docker Deployment

## Overview
This project provides a Dockerized deployment of ManageEngine OpManager for network monitoring. It uses CentOS 9 as the base image, installs OpenJDK 17, and runs OpManager as a non-root user for security.

## Quick Start (Linux/Docker)

1. **Prerequisites**:
   - Docker 20+ and Docker Compose 2+
   - 8GB+ RAM, 4+ CPU cores, 50GB+ disk space

2. **Clone/Build**:
   ```
   git clone <repo>
   cd opmanager-docker
   ```

3. **Deploy**:
   ```
   docker compose up -d --build
   ```

4. **Access**:
   - Web UI: http://localhost:8060 (initial setup wizard)
   - HTTPS: https://localhost:8443
   - Default credentials: admin/admin (change immediately!)

5. **Stop/Remove**:
   ```
   docker compose down
   docker compose down -v  # Remove volumes (data loss!)
   ```

## Resource Requirements
| Component | Minimum | Recommended |
|-----------|---------|-------------|
| **CPU** | 2 cores | 4+ cores |
| **RAM** | 8GB | 16GB+ |
| **Disk** | 50GB (SSD) | 100GB+ |
| **Java Heap** | -Xms2g -Xmx4g | -Xms4g -Xmx8g |

Adjust `JAVA_OPTS` in [`docker-compose.yml`](docker-compose.yml) for your workload.

## Persistent Volumes
Data is persisted across restarts:
- `opmanager_mysql`: MySQL database
- `opmanager_conf`: Configuration
- `opmanager_logs`: Logs (rotate regularly)
- `opmanager_pgbackup`: Backups

**Backup Command**:
```
docker compose run --rm opmanager tar czf /backup/opmanager-backup-$(date +%Y%m%d).tar.gz -C /opt/ManageEngine/OpManager {Mysql,conf,pgbackup}
```

## Security Best Practices
1. **Non-Root User**: OpManager runs as `opmanager` user (no sudo in runtime).
2. **Port Exposure**:
   - Only expose necessary ports (8060 HTTP, 8443 HTTPS).
   - Use reverse proxy (Nginx/Traefik) with TLS termination.
3. **Secrets Management**:
   - Set DB passwords via env vars (extend docker-compose).
   - Avoid hardcoding credentials.
4. **Firewall**:
   ```
   # Linux example (ufw)
   sudo ufw allow 8060/tcp  # Or restrict to IP
   sudo ufw enable
   ```
5. **Updates**:
   - Monitor ManageEngine releases.
   - Rebuild: `docker compose build --no-cache`.
6. **Hardening**:
   - Enable HTTPS only.
   - Use Docker secrets for sensitive data.
   - Scan images: `docker scout` or Trivy.
   - Resource limits prevent DoS:
     ```yaml
     deploy:
       resources:
         limits:
           cpus: '4'
           memory: 8G
     ```
7. **Monitoring**:
   - Integrate with Prometheus/Grafana (see below).

## Healthcheck & Restart
- Built-in healthcheck pings web UI.
- `restart: unless-stopped` for production.

## Integrations
1. **Prometheus + Grafana**:
   - Add node-exporter sidecar.
   - OpManager JMX exporter via JAVA_OPTS.

2. **Slack/Email Alerts**:
   - Configure in OpManager UI: Admin > Notifications.

3. **Automation Script** (deploy.sh):
   ```bash
   #!/bin/bash
   docker compose up -d --build
   until curl -f http://localhost:8060; do sleep 10; done
   echo "OpManager ready!"
   ```

## Troubleshooting
- Logs: `docker compose logs -f opmanager`
- Shell: `docker compose exec opmanager bash`
- Installer URL outdated? Update [`Dockerfile`](Dockerfile):L9.

**License**: Free edition (125 devices). Enterprise requires license key in UI.