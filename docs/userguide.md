# OpManager Docker User Guide

## Initial Setup

### 1. **Access Web UI**
- Open: http://localhost:8060 (or your host IP:8060)
- Initial login: **admin / admin** (change immediately!)

### 2. **License & Wizard**
```
1. Accept EULA
2. Enter License Key (Free: 125 devices)
3. Set Admin Password
4. Configure DB: Use embedded MySQL (default)
5. Network Settings: Auto-detect or manual SNMP
6. Finish → Dashboard
```

**Pro Tip**: Save wizard config to [`opmanager_conf`](../volumes/opmanager_conf/server.xml)

## Core Features

### Adding Devices
1. **Discovery**:
   - Inventory > Discovery > Add Scan
   - IP Range: 192.168.1.0/24
   - SNMP v2c/v3: Community "public" or credentials
   - Protocols: ICMP, SNMP, WMI, SSH, Telnet

2. **Manual Add**:
   - Inventory > Add Device
   - Display Name, IP, SNMP OID (.1.3.6.1.2.1.1.5.0)

### Dashboards
- **Home**: Availability, alarms, top talkers.
- **Customize**: Add widgets (CPU, Traffic, Latency).
- **3D Maps**: Visualize topology.

## Monitoring

### 1. **Interfaces & Performance**
- Monitors > Physical/Interface
- Add Monitors: CPU >95%, Traffic >80%, Latency >100ms

### 2. **Alarms & Notifications**
```
Admin > Notifications > Profiles
• Email: smtp.gmail.com:587 (TLS)
• Slack: Webhook URL
• SMS/Traps/Syslog
```

**Escalation Rules**:
- Critical: Page + Slack
- Warning: Email

### 3. **Reports**
- Reports > Generate:
  | Type | Use Case |
  |------|----------|
  | Availability | Uptime % |
  | Performance | Bandwidth trends |
  | Inventory | Device list (CSV/PDF) |
  | Custom SQL | Advanced queries |

**Scheduled**: Daily/Weekly to Email.

## Advanced Usage

### Workflow Automation
1. **Business Views**: Group by VLAN/Location.
2. **IP SLA**: WAN latency monitoring.
3. **NetFlow**: Top apps/protocols (add NetFlow plugin).

### Troubleshooting Devices
```
1. Alarms > Clear false positives
2. Monitors > Test SNMP connectivity
3. Reports > Historical data
4. Logs: docker compose logs opmanager | grep "deviceIP"
```

**Common Monitors**:
```yaml
# Threshold Examples
CPU: >90% → Critical
Disk: >85% → Warning
Interface Errors: >0.1%
```

## Best Practices
- **Start Small**: 10 devices → Scale.
- **SNMPv3**: Auth/Priv for prod.
- **Backup Weekly**: See [`administration.md`](administration.md).
- **Update Patches**: Monthly.

## UI Navigation
```
┌─ Dashboard ──────────────┐
├─ Inventory (Devices)     │
├─ Maps                    │
├─ Alarms                  │
├─ Reports                 │
├─ Admin (Users/Alarms)    │
└─ Settings (Notifications)│
```

**Keyboard Shortcuts**: F5 refresh, Ctrl+P reports.

For ops/backups: [`administration.md`](administration.md). Architecture: [`architecture.md`](architecture.md).

**Support**: ManageEngine KB + Docker logs.