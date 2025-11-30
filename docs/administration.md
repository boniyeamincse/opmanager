# OpManager Docker Administration Guide

## Daily Operations

### 1. **Status Checks**
```
docker compose ps          # Container health
docker compose logs -f     # Live logs
docker compose top         # Processes
```

### 2. **Backups**
**Automated (via cron/host)**:
```bash
#!/bin/bash
cd ~/opmanager-docker
docker compose run --rm opmanager tar czf /backup/opmanager-$(date +%Y%m%d).tar.gz \
  -C /opt/ManageEngine/OpManager Mysql conf pgbackup
```

**Manual**:
```
docker compose exec opmanager tar czf /host-backup.tar.gz -C /opt/ManageEngine/OpManager {Mysql,conf}
```

**Restore**:
```
docker compose down -v
# Copy backup to volumes
docker compose up -d
```

### 3. **Updates**
1. Update OpManager UI: Admin > Hotfix/Patch.
2. Rebuild image:
   ```
   cd ~/opmanager-docker
   # Update Dockerfile URL if new version
   docker compose build --no-cache --pull
   docker compose up -d
   ```

### 4. **Resource Tuning**
Edit [`docker-compose.yml`](../docker-compose.yml):
```yaml
environment:
  - JAVA_OPTS=-Xms4g -Xmx8g  # For 1000+ devices
deploy:  # Swarm mode
  resources:
    limits:
      cpus: '4'
      memory: 12G
```

### 5. **Log Rotation**
Host cron:
```bash
# /etc/cron.daily/opmanager-logs
docker compose run --rm opmanager find /opt/ManageEngine/OpManager/logs -name "*.log" -type f -mtime +7 -delete
```

## Monitoring & Alerts

### Container Metrics
Add to `docker-compose.yml`:
```yaml
services:
  prometheus:
    image: prom/prometheus
    volumes:
      - ./prometheus.yml:/etc/prometheus/prometheus.yml
```

**prometheus.yml** snippet:
```yaml
scrape_configs:
  - job_name: 'opmanager'
    static_configs:
      - targets: ['host.docker.internal:9324']  # cAdvisor or JMX
```

### OpManager Internal
- Admin > Alarms > Notification Profiles (Email/Slack).
- Reports > Scheduled Reports.

## Scaling & HA

### Probes (Distributed)
Extend compose:
```yaml
services:
  central:
    # Existing
  probe1:
    build: .
    environment:
      - OP_MANAGER_MODE=probe
      - CENTRAL_SERVER=central:8060
```

### Kubernetes
```
kubectl apply -f k8s/opmanager-deployment.yaml
# See contrib/k8s/
```

## Troubleshooting

| Issue | Command | Fix |
|-------|---------|-----|
| **OOMKilled** | `docker stats` | Increase JAVA_OPTS/memory limits |
| **Healthcheck fail** | `docker compose logs` | Check MySQL init (5-10min startup) |
| **Port bind** | `netstat -tuln \| grep 8060` | Stop conflicting services |
| **Volume perm** | `ls -la volumes/` | `chown -R 1000:1000 volumes/` |
| **Installer fail** | Dockerfile L9 | Update URL to latest bin |

**Debug Shell**:
```
docker compose exec opmanager bash
cd /opt/ManageEngine/OpManager
./bin/OpManagerService status
```

**JMX Debug**:
```
JAVA_OPTS="$JAVA_OPTS -Dcom.sun.management.jmxremote"
```

## Security Hardening
- **Reverse Proxy**: Nginx/Traefik with Let's Encrypt.
- **Secrets**: `.env` file or Docker secrets.
- **Scan**: `docker scout cimage manageengine-opmanager`.
- **Audit**: Enable OpManager syslog forwarding.

See [`architecture.md`](architecture.md), [`userguide.md`](userguide.md).