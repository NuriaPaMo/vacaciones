# Deployment Guide

> **BOLT Framework Stage:** TRANSITION - Deployment Documentation

**Application:** {APPLICATION_NAME}
**Version:** {VERSION}
**Environment:** {Development | Staging | Production}
**Last Updated:** {DATE}
**Owner:** {TEAM/PERSON}

---

## 1. Overview

### Application Description

{Brief description of the application and its purpose}

### Architecture

```text
┌─────────────────────────────────────────────────────────────┐
│                    {Architecture Diagram}                    │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│   [Load Balancer] → [App Servers] → [Database]              │
│                          ↓                                   │
│                    [Cache Layer]                             │
│                          ↓                                   │
│                 [Message Queue]                              │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

---

## 2. Prerequisites

### Infrastructure

| Component | Requirement               | Notes           |
| --------- | ------------------------- | --------------- |
| OS        | {Linux/Windows} {version} |                 |
| CPU       | {cores} cores             |                 |
| Memory    | {GB} GB                   |                 |
| Storage   | {GB} GB                   | SSD recommended |
| Network   | {bandwidth}               |                 |

### Software Dependencies

| Software   | Version   | Purpose           |
| ---------- | --------- | ----------------- |
| {software} | {version} | {purpose}         |
| Docker     | 24.0+     | Container runtime |
| Node.js    | 20.x LTS  | Runtime           |
| PostgreSQL | 15+       | Database          |

### Credentials/Secrets Required

| Secret            | Source                  | Environment Variable |
| ----------------- | ----------------------- | -------------------- |
| Database password | {vault/secrets manager} | `DB_PASSWORD`        |
| API keys          | {source}                | `API_KEY`            |
| SSL certificates  | {source}                | `SSL_CERT_PATH`      |

### Network Requirements

| Port | Protocol | Purpose     | Source   |
| ---- | -------- | ----------- | -------- |
| 443  | HTTPS    | API traffic | Public   |
| 5432 | TCP      | Database    | Internal |
| 6379 | TCP      | Redis       | Internal |

---

## 3. Environment Configuration

### Environment Variables

```bash
# Application
APP_NAME={name}
APP_ENV={development|staging|production}
APP_PORT=3000
APP_LOG_LEVEL={debug|info|warn|error}

# Database
DB_HOST={host}
DB_PORT=5432
DB_NAME={database}
DB_USER={user}
DB_PASSWORD={password}
DB_SSL={true|false}

# Cache
REDIS_URL=redis://{host}:{port}

# External Services
API_BASE_URL={url}
API_KEY={key}

# Feature Flags
FEATURE_NEW_UI={true|false}
```

### Configuration Files

| File          | Location       | Purpose               |
| ------------- | -------------- | --------------------- |
| `config.yaml` | `/app/config/` | Application config    |
| `nginx.conf`  | `/etc/nginx/`  | Reverse proxy         |
| `.env`        | `/app/`        | Environment variables |

---

## 4. Deployment Procedures

### 4.1 Standard Deployment

#### Pre-Deployment Checklist

- [ ] Release notes reviewed
- [ ] Database backup completed
- [ ] Rollback plan confirmed
- [ ] Monitoring alerts configured
- [ ] Team notified

#### Step 1: Prepare Environment

```bash
# SSH to deployment server
ssh {user}@{server}

# Navigate to application directory
cd /opt/{application}

# Create backup of current deployment
cp -r current current.backup.$(date +%Y%m%d_%H%M%S)
```

#### Step 2: Pull New Version

```bash
# Pull latest Docker images
docker pull {registry}/{image}:{tag}

# Or for Git-based deployment
git fetch origin
git checkout tags/{version}
```

#### Step 3: Run Database Migrations

```bash
# Backup database first
pg_dump -h {host} -U {user} {database} > backup_$(date +%Y%m%d).sql

# Run migrations
npm run migrate
# or
docker exec {container} npm run migrate
```

#### Step 4: Deploy Application

```bash
# Using Docker Compose
docker-compose pull
docker-compose up -d --remove-orphans

# Or using Kubernetes
kubectl apply -f k8s/
kubectl rollout status deployment/{deployment-name}
```

#### Step 5: Verify Deployment

```bash
# Check health endpoint
curl -f http://localhost:{port}/health

# Check logs
docker logs -f {container} --tail 100

# Run smoke tests
npm run test:smoke
```

### 4.2 Zero-Downtime Deployment

#### Blue-Green Strategy

```bash
# Deploy to green environment
kubectl set image deployment/app-green app={image}:{new-tag}

# Wait for rollout
kubectl rollout status deployment/app-green

# Run verification tests
./scripts/verify-deployment.sh green

# Switch traffic
kubectl patch service app-lb -p '{"spec":{"selector":{"version":"green"}}}'

# Scale down blue (after verification period)
kubectl scale deployment/app-blue --replicas=0
```

#### Rolling Update Strategy

```bash
# Kubernetes rolling update
kubectl set image deployment/{name} {container}={image}:{tag}

# Monitor rollout
kubectl rollout status deployment/{name}

# Rollback if needed
kubectl rollout undo deployment/{name}
```

---

## 5. Rollback Procedures

### Automatic Rollback Triggers

- Health check failures for > 3 minutes
- Error rate > 5%
- Response time p95 > 5 seconds

### Manual Rollback Steps

#### Docker Compose

```bash
# Stop current containers
docker-compose down

# Restore previous version
docker-compose -f docker-compose.previous.yml up -d
```

#### Kubernetes

```bash
# Rollback to previous revision
kubectl rollout undo deployment/{name}

# Or rollback to specific revision
kubectl rollout undo deployment/{name} --to-revision={n}
```

#### Database Rollback

```bash
# Restore from backup
psql -h {host} -U {user} -d {database} < backup_YYYYMMDD.sql

# Or run down migrations
npm run migrate:down
```

---

## 6. Health Checks

### Endpoints

| Endpoint        | Method | Expected Response | Purpose      |
| --------------- | ------ | ----------------- | ------------ |
| `/health`       | GET    | 200 OK            | Basic health |
| `/health/ready` | GET    | 200 OK            | Readiness    |
| `/health/live`  | GET    | 200 OK            | Liveness     |

### Health Check Response

```json
{
  "status": "healthy",
  "version": "{version}",
  "timestamp": "{ISO8601}",
  "checks": {
    "database": "healthy",
    "cache": "healthy",
    "external_api": "healthy"
  }
}
```

### Monitoring Commands

```bash
# Check application health
curl -s http://localhost:{port}/health | jq

# Check container status
docker ps --filter name={app}

# Check resource usage
docker stats {container}
```

---

## 7. Logging & Monitoring

### Log Locations

| Log         | Location                    | Retention |
| ----------- | --------------------------- | --------- |
| Application | `/var/log/{app}/app.log`    | 30 days   |
| Access      | `/var/log/{app}/access.log` | 30 days   |
| Error       | `/var/log/{app}/error.log`  | 90 days   |

### Log Format

```text
{timestamp} {level} [{request-id}] {message} {context}
```

### Monitoring Dashboards

| Dashboard | URL   | Purpose |
| --------- | ----- | ------- |
| Grafana   | {url} | Metrics |
| Kibana    | {url} | Logs    |
| Datadog   | {url} | APM     |

### Key Metrics

| Metric            | Alert Threshold | Dashboard |
| ----------------- | --------------- | --------- |
| Error rate        | > 1%            | {link}    |
| Response time p95 | > 500ms         | {link}    |
| CPU usage         | > 80%           | {link}    |
| Memory usage      | > 85%           | {link}    |

---

## 8. Troubleshooting

### Common Issues

#### Application Won't Start

```bash
# Check logs
docker logs {container} --tail 500

# Check configuration
docker exec {container} cat /app/config.yaml

# Verify environment variables
docker exec {container} env | grep APP_
```

#### Database Connection Issues

```bash
# Test database connectivity
pg_isready -h {host} -p {port} -U {user}

# Check connection pool
docker exec {container} npm run db:status
```

#### High Memory Usage

```bash
# Check memory
docker stats {container}

# Trigger garbage collection (Node.js)
docker exec {container} kill -SIGUSR2 1

# Restart with limits
docker update --memory={limit} {container}
```

### Diagnostic Commands

```bash
# Get container shell
docker exec -it {container} /bin/sh

# Network debugging
docker exec {container} curl -v {endpoint}

# Check DNS resolution
docker exec {container} nslookup {hostname}
```

---

## 9. Security Considerations

### SSL/TLS

- Certificates location: `/etc/ssl/certs/{app}/`
- Certificate renewal: Automated via Let's Encrypt/Certbot
- Minimum TLS version: 1.2

### Secrets Management

- Secrets stored in: {HashiCorp Vault / AWS Secrets Manager / Azure Key Vault}
- Rotation policy: {frequency}
- Access audit: Enabled

### Network Security

- Firewall rules: See `infrastructure/firewall.tf`
- Security groups: Configured via IaC
- WAF: Enabled on load balancer

---

## 10. Contacts

### Escalation Path

| Level | Contact | Response Time |
| ----- | ------- | ------------- |
| L1    | {team}  | 15 min        |
| L2    | {team}  | 30 min        |
| L3    | {team}  | 1 hour        |

### On-Call

- Schedule: {link to schedule}
- Contact: {phone/slack}

---

*Generated by Bolt Ops Agent*
