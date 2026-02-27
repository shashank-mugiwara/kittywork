# Kittywork Deployment Guide

This guide covers building, running, and deploying the Kittywork Job Management and Candidate Application Platform using Docker and Docker Compose.

## Table of Contents

- [Prerequisites](#prerequisites)
- [Quick Start (Local Development)](#quick-start-local-development)
- [Environment Configuration](#environment-configuration)
- [Docker Build and Push](#docker-build-and-push)
- [Health Checks and Verification](#health-checks-and-verification)
- [Database Migrations](#database-migrations)
- [AWS S3 Integration](#aws-s3-integration)
- [Logs and Debugging](#logs-and-debugging)
- [Production Deployment](#production-deployment)
- [Troubleshooting](#troubleshooting)

---

## Prerequisites

### Local Development
- **Docker** (v20.10+) with Docker Compose (v2.0+)
- **Java 25** (optional, only if running without Docker)
- **Maven 3.8+** (optional, only if building locally without Docker)
- **curl** or **Postman** for API testing

### Production Deployment
- **Docker Registry** (Docker Hub, ECR, or private registry)
- **AWS Account** with:
  - S3 bucket for resume storage
  - IAM credentials or role for S3 access
- **Kubernetes** cluster (optional, for orchestration) or Docker Swarm
- **PostgreSQL** database (managed RDS, self-hosted, or containerized)

---

## Quick Start (Local Development)

### 1. Clone the Repository

```bash
git clone https://github.com/shashank-mugiwara/kittywork.git
cd kittywork
```

### 2. Create Environment File

```bash
cp .env.example .env
```

Edit `.env` and update sensitive values:
```bash
# For local dev, these defaults work:
DB_PASSWORD=kittywork_dev_password
AWS_ACCESS_KEY_ID=<your-aws-access-key>
AWS_SECRET_ACCESS_KEY=<your-aws-secret-key>
AWS_S3_BUCKET=kittywork-resumes-dev
```

### 3. Build and Start Services

```bash
# Build the Docker image and start all services
docker compose up --build

# Or run in background
docker compose up -d --build
```

Expected output:
```
Creating kittywork-db  ... done
Creating kittywork-app ... done
Attaching to kittywork-db, kittywork-app
kittywork-db  | 2025-01-10 12:00:00.000 UTC [1] LOG:  database system is ready to accept connections
kittywork-app | 2025-01-10 12:00:05.123 INFO  [main] Application started in 2.456 seconds
```

### 4. Verify Services Are Running

```bash
# Check running containers
docker compose ps

# Output:
# NAME              COMMAND                  SERVICE      STATUS       PORTS
# kittywork-db      "docker-entrypoint.sh"   postgres     Up 2 mins    0.0.0.0:5432->5432/tcp
# kittywork-app     "sh -c 'java $JAVA_OPT…" app          Up 1 min     0.0.0.0:8080->8080/tcp
```

### 5. Test the Application

```bash
# Health check
curl http://localhost:8080/actuator/health

# Expected response:
# {"status":"UP","components":{"db":{"status":"UP"},"diskSpace":{"status":"UP"},...}}

# List all jobs (public endpoint)
curl http://localhost:8080/api/jobs

# Expected response:
# []
```

### 6. Stop Services

```bash
# Stop and remove containers
docker compose down

# Stop containers without removing (preserves volumes)
docker compose stop

# Remove everything including volumes
docker compose down -v
```

---

## Environment Configuration

All configuration is managed via environment variables (12-factor app methodology).

### Required Variables (Must Set)

| Variable | Purpose | Example |
|----------|---------|---------|
| `DB_PASSWORD` | PostgreSQL password | `secure_password_123` |
| `AWS_ACCESS_KEY_ID` | AWS credential | `AKIAIOSFODNN7EXAMPLE` |
| `AWS_SECRET_ACCESS_KEY` | AWS credential | `wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY` |
| `AWS_S3_BUCKET` | S3 bucket name | `kittywork-resumes-prod` |

### Optional Variables (Defaults Provided)

| Variable | Default | Purpose |
|----------|---------|---------|
| `DB_HOST` | `postgres` | PostgreSQL hostname |
| `DB_PORT` | `5432` | PostgreSQL port |
| `DB_NAME` | `kittywork` | Database name |
| `DB_USER` | `kittywork` | PostgreSQL user |
| `AWS_S3_REGION` | `us-east-1` | AWS region |
| `APP_PORT` | `8080` | Application port |
| `SPRING_PROFILES_ACTIVE` | `docker` | Spring profiles |
| `LOGGING_LEVEL_ROOT` | `INFO` | Root logging level |

### Security Best Practices

1. **Never commit `.env` to Git**
   ```bash
   echo ".env" >> .gitignore
   git rm --cached .env 2>/dev/null || true
   ```

2. **Use secrets management in production**
   - AWS Secrets Manager
   - HashiCorp Vault
   - Kubernetes Secrets
   - Docker Secrets (for Swarm)

3. **Rotate credentials regularly**
   - AWS access keys every 90 days
   - Database passwords every 6 months

---

## Docker Build and Push

### Local Build

```bash
# Build image with default tag
docker build -t kittywork:latest .

# Build with custom tag
docker build -t kittywork:v1.0.0 .

# Build without cache (fresh build)
docker build --no-cache -t kittywork:latest .

# Verify image
docker image ls | grep kittywork
```

### Push to Registry

#### Docker Hub

```bash
# Login to Docker Hub
docker login

# Tag image for Docker Hub
docker tag kittywork:latest <your-docker-username>/kittywork:latest
docker tag kittywork:latest <your-docker-username>/kittywork:v1.0.0

# Push to Docker Hub
docker push <your-docker-username>/kittywork:latest
docker push <your-docker-username>/kittywork:v1.0.0
```

#### AWS ECR (Elastic Container Registry)

```bash
# Login to ECR
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin <account-id>.dkr.ecr.us-east-1.amazonaws.com

# Tag image for ECR
docker tag kittywork:latest <account-id>.dkr.ecr.us-east-1.amazonaws.com/kittywork:latest

# Push to ECR
docker push <account-id>.dkr.ecr.us-east-1.amazonaws.com/kittywork:latest

# Create repository if it doesn't exist
aws ecr create-repository --repository-name kittywork --region us-east-1
```

#### Private Docker Registry

```bash
# Tag image
docker tag kittywork:latest registry.company.com/kittywork:latest

# Push
docker push registry.company.com/kittywork:latest
```

---

## Health Checks and Verification

### Application Health Endpoints

The application exposes Spring Actuator endpoints for monitoring:

```bash
# Full health check (includes all components)
curl http://localhost:8080/actuator/health

# Readiness probe (for Kubernetes)
curl http://localhost:8080/actuator/health/readiness

# Liveness probe (for Kubernetes)
curl http://localhost:8080/actuator/health/liveness

# Application info
curl http://localhost:8080/actuator/info

# Metrics (Prometheus format)
curl http://localhost:8080/actuator/metrics
```

### Docker Health Check

Docker Compose continuously monitors container health:

```bash
# Check container health status
docker compose ps

# Output shows HEALTH status:
# STATUS: Up 2 minutes (healthy)
```

### Database Connectivity

```bash
# Connect to PostgreSQL container
docker exec -it kittywork-db psql -U kittywork -d kittywork

# List tables (after migrations)
\dt

# Exit psql
\q
```

### API Testing

```bash
# Create a job (recruiter endpoint)
curl -X POST http://localhost:8080/api/recruiter/jobs \
  -H "Content-Type: application/json" \
  -d '{
    "title": "Senior Java Developer",
    "description": "Build amazing apps",
    "company": "TechCorp"
  }'

# Get all published jobs
curl http://localhost:8080/api/jobs

# Submit application with resume
curl -X POST http://localhost:8080/api/applications \
  -F "candidateName=John Doe" \
  -F "email=john@example.com" \
  -F "jobId=1" \
  -F "resume=@/path/to/resume.pdf"
```

---

## Database Migrations

Liquibase handles database migrations automatically on application startup.

### Migration Files

Database migration files are located in `src/main/resources/db/changelog/`:

- `db.changelog-master.yaml` — Master changelog (orchestrates all migrations)
- `db/v1__initial_schema.yaml` — Initial schema creation
- `db/v2__add_indexes.yaml` — Performance indexes
- (Additional migration files as needed)

### Automatic Migration

On application startup, Liquibase:
1. Checks the `databasechangelog` table
2. Identifies unapplied migrations
3. Executes migrations in order
4. Records completion in the changelog table

```bash
# View migration history
docker exec -it kittywork-db psql -U kittywork -d kittywork -c \
  "SELECT id, author, filename, dateexecuted, orderexecuted FROM databasechangelog ORDER BY orderexecuted;"
```

### Manual Migration (if needed)

```bash
# Connect to container and run Liquibase manually
docker exec -it kittywork-app liquibase --changeLogFile=db/changelog/db.changelog-master.yaml update
```

### Rollback Strategy

For production, maintain a rollback procedure:

```yaml
# Example rollback changelog
- changeSet:
    id: "3"
    author: "devops"
    comment: "Rollback: Remove column if needed"
    changes:
      - dropColumn:
          tableName: applications
          columnName: problematic_column
    rollback:
      - addColumn:
          tableName: applications
          columns:
            - column:
                name: problematic_column
                type: VARCHAR(255)
```

---

## AWS S3 Integration

### S3 Bucket Setup

```bash
# Create S3 bucket for resumes
aws s3 mb s3://kittywork-resumes-prod --region us-east-1

# Enable versioning (for recovery)
aws s3api put-bucket-versioning \
  --bucket kittywork-resumes-prod \
  --versioning-configuration Status=Enabled

# Block public access
aws s3api put-public-access-block \
  --bucket kittywork-resumes-prod \
  --public-access-block-configuration \
    "BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true"

# Set lifecycle policy (optional, delete old resumes after 90 days)
aws s3api put-bucket-lifecycle-configuration \
  --bucket kittywork-resumes-prod \
  --lifecycle-configuration '{
    "Rules": [
      {
        "ID": "DeleteOldResumes",
        "Status": "Enabled",
        "Prefix": "resumes/",
        "Expiration": {"Days": 90},
        "NoncurrentVersionExpiration": {"NoncurrentDays": 30}
      }
    ]
  }'
```

### IAM User for S3 Access

```bash
# Create IAM user
aws iam create-user --user-name kittywork-app

# Create access key
aws iam create-access-key --user-name kittywork-app

# Attach S3 policy
aws iam put-user-policy --user-name kittywork-app --policy-name S3Access \
  --policy-document '{
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Action": ["s3:GetObject", "s3:PutObject", "s3:DeleteObject"],
        "Resource": "arn:aws:s3:::kittywork-resumes-prod/*"
      },
      {
        "Effect": "Allow",
        "Action": ["s3:ListBucket"],
        "Resource": "arn:aws:s3:::kittywork-resumes-prod"
      }
    ]
  }'
```

### Docker Configuration for S3

In `.env`:
```bash
AWS_S3_BUCKET=kittywork-resumes-prod
AWS_S3_REGION=us-east-1
AWS_ACCESS_KEY_ID=AKIA...
AWS_SECRET_ACCESS_KEY=...
```

Or use IAM role in Kubernetes/ECS:
```yaml
# Kubernetes example
apiVersion: v1
kind: ServiceAccount
metadata:
  name: kittywork-app
  annotations:
    eks.amazonaws.com/role-arn: arn:aws:iam::ACCOUNT_ID:role/kittywork-app-role
```

---

## Logs and Debugging

### View Application Logs

```bash
# Real-time logs from all services
docker compose logs -f

# Logs from app only
docker compose logs -f app

# Logs from PostgreSQL only
docker compose logs -f postgres

# Last 100 lines
docker compose logs --tail 100 app

# Show timestamps
docker compose logs -t app

# Follow specific container since 1 hour ago
docker logs --since 1h -f kittywork-app
```

### Log Levels

Adjust logging in `.env`:

```bash
# Root logger
LOGGING_LEVEL_ROOT=DEBUG

# Application-specific logger
LOGGING_LEVEL_COM_KITTYWORK=DEBUG
```

### Access Container Shell

```bash
# Bash shell in app container
docker exec -it kittywork-app /bin/bash

# Python shell in database container
docker exec -it kittywork-db psql -U kittywork -d kittywork

# Check disk usage
docker exec kittywork-app du -sh /app
```

### Performance Monitoring

```bash
# View container resource usage
docker stats

# Memory and CPU limits
docker inspect kittywork-app | grep -A 10 '"Memory"'

# Check JVM memory usage
docker exec kittywork-app jps -l -m
```

---

## Production Deployment

### Single Host Deployment (Docker Compose on EC2/VM)

```bash
# 1. Create EC2 instance with Docker
# Use Ubuntu 22.04 LTS AMI
# Install Docker:
# sudo apt-get update && sudo apt-get install -y docker.io docker-compose

# 2. Clone repository
git clone https://github.com/shashank-mugiwara/kittywork.git
cd kittywork

# 3. Create production .env
cat > .env << EOF
DB_PASSWORD=$(openssl rand -base64 32)
AWS_S3_BUCKET=kittywork-resumes-prod
AWS_S3_REGION=us-east-1
AWS_ACCESS_KEY_ID=$(aws configure get aws_access_key_id)
AWS_SECRET_ACCESS_KEY=$(aws configure get aws_secret_access_key)
SPRING_PROFILES_ACTIVE=prod
LOGGING_LEVEL_ROOT=WARN
EOF

# 4. Start services
docker compose up -d --build

# 5. Configure reverse proxy (nginx)
# See Nginx configuration example below
```

### Nginx Reverse Proxy Configuration

```nginx
# /etc/nginx/sites-available/kittywork
upstream kittywork_backend {
    server localhost:8080;
}

server {
    listen 80;
    listen [::]:80;
    server_name api.kittywork.com;

    # Redirect HTTP to HTTPS
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl http2;
    listen [::]:443 ssl http2;
    server_name api.kittywork.com;

    # SSL certificates (from Let's Encrypt or AWS ACM)
    ssl_certificate /etc/letsencrypt/live/api.kittywork.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/api.kittywork.com/privkey.pem;

    # Security headers
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-Frame-Options "DENY" always;
    add_header X-XSS-Protection "1; mode=block" always;

    # Compression
    gzip on;
    gzip_types text/plain text/css application/json application/javascript;
    gzip_min_length 1000;

    # Rate limiting
    limit_req_zone $binary_remote_addr zone=general:10m rate=10r/s;
    limit_req zone=general burst=20 nodelay;

    # Proxy settings
    location / {
        proxy_pass http://kittywork_backend;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
    }

    # Health check endpoint (no logging)
    location /actuator/health {
        proxy_pass http://kittywork_backend;
        access_log off;
    }
}
```

### Kubernetes Deployment (Optional)

```yaml
# deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: kittywork-app
  labels:
    app: kittywork
spec:
  replicas: 3
  selector:
    matchLabels:
      app: kittywork
  template:
    metadata:
      labels:
        app: kittywork
    spec:
      serviceAccountName: kittywork-app
      containers:
      - name: app
        image: <registry>/kittywork:v1.0.0
        imagePullPolicy: IfNotPresent
        ports:
        - containerPort: 8080
          name: http
        env:
        - name: SPRING_DATASOURCE_URL
          valueFrom:
            secretKeyRef:
              name: db-secret
              key: url
        - name: AWS_S3_BUCKET
          valueFrom:
            configMapKeyRef:
              name: app-config
              key: s3-bucket
        - name: AWS_ROLE_ARN
          value: arn:aws:iam::ACCOUNT:role/kittywork-app
        resources:
          requests:
            memory: "256Mi"
            cpu: "250m"
          limits:
            memory: "512Mi"
            cpu: "500m"
        livenessProbe:
          httpGet:
            path: /actuator/health/liveness
            port: 8080
          initialDelaySeconds: 40
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /actuator/health/readiness
            port: 8080
          initialDelaySeconds: 20
          periodSeconds: 5
      affinity:
        podAntiAffinity:
          preferredDuringSchedulingIgnoredDuringExecution:
          - weight: 100
            podAffinityTerm:
              labelSelector:
                matchExpressions:
                - key: app
                  operator: In
                  values:
                  - kittywork
              topologyKey: kubernetes.io/hostname
```

---

## Troubleshooting

### Container Won't Start

```bash
# Check logs
docker compose logs app

# Common issues:
# 1. Port already in use
netstat -tlnp | grep 8080
# Kill the process or change APP_PORT in .env

# 2. Database connection failed
# Check if postgres is running: docker compose logs postgres
# Check credentials in .env

# 3. OutOfMemory error
# Increase JAVA_OPTS in .env: -Xmx1024m
```

### Database Connection Errors

```bash
# Test PostgreSQL connectivity
docker exec kittywork-app psql -h postgres -U kittywork -d kittywork -c "SELECT 1;"

# Check PostgreSQL logs
docker compose logs postgres

# Verify credentials
grep DB_ .env

# Connect directly to test
docker exec -it kittywork-db psql -U kittywork -d kittywork
```

### S3 Upload Failures

```bash
# Check AWS credentials
docker exec kittywork-app env | grep AWS

# Test S3 access
docker exec kittywork-app aws s3 ls s3://kittywork-resumes-prod/

# Check IAM permissions
aws iam simulate-principal-policy \
  --policy-source-arn arn:aws:iam::ACCOUNT_ID:user/kittywork-app \
  --action-names s3:PutObject \
  --resource-arns arn:aws:s3:::kittywork-resumes-prod/*
```

### High Memory Usage

```bash
# Check heap size
docker stats kittywork-app

# Adjust in .env
JAVA_OPTS=-Xmx256m -Xms128m

# Restart
docker compose restart app
```

### API Response Slow

```bash
# Check application metrics
curl http://localhost:8080/actuator/metrics/http.server.requests

# Check database performance
docker exec kittywork-db psql -U kittywork -d kittywork -c \
  "SELECT query, calls, mean_time FROM pg_stat_statements ORDER BY mean_time DESC LIMIT 10;"

# Review application logs
docker compose logs -f app | grep "duration"
```

### Volume Permission Issues

```bash
# Fix volume permissions
docker exec kittywork-app chown -R appuser:appuser /app/logs /app/uploads

# Or use Docker volume drivers with proper permissions
# Check ownership
docker exec kittywork-app ls -la /app/
```

---

## Maintenance & Monitoring

### Backup Database

```bash
# Full backup
docker exec kittywork-db pg_dump -U kittywork kittywork > kittywork_backup_$(date +%Y%m%d_%H%M%S).sql

# Compressed backup
docker exec kittywork-db pg_dump -U kittywork -F custom kittywork > kittywork_backup_$(date +%Y%m%d_%H%M%S).dump

# Backup to S3
docker exec kittywork-db pg_dump -U kittywork kittywork | gzip | aws s3 cp - s3://kittywork-backups/db_$(date +%Y%m%d_%H%M%S).sql.gz
```

### Restore Database

```bash
# From SQL dump
docker exec -i kittywork-db psql -U kittywork kittywork < kittywork_backup.sql

# From custom format dump
docker exec -i kittywork-db pg_restore -U kittywork -d kittywork < kittywork_backup.dump
```

### Update Application

```bash
# 1. Pull latest code
git pull origin main

# 2. Rebuild image
docker compose build --no-cache app

# 3. Restart with new image
docker compose up -d app

# 4. Verify health
curl http://localhost:8080/actuator/health
```

### Monitor Disk Space

```bash
# Container disk usage
docker exec kittywork-db du -sh /var/lib/postgresql/data
docker exec kittywork-app du -sh /app/logs /app/uploads

# Host disk usage
df -h

# Clean up old volumes
docker volume prune
```

---

## Security Checklist

- [ ] `.env` file added to `.gitignore` (never commit secrets)
- [ ] Weak default passwords changed
- [ ] S3 bucket has private access controls
- [ ] Database backups encrypted at rest
- [ ] SSL/TLS certificates installed (production)
- [ ] Firewall rules restrict port access
- [ ] Regular security updates applied
- [ ] Logs retention configured
- [ ] Monitoring and alerting configured
- [ ] Disaster recovery plan documented

---

## Support & Resources

- **Documentation:** See [ARCHITECTURE.md](./ARCHITECTURE.md)
- **API Documentation:** [Postman Collection](./postman-collection.json)
- **Issues:** [GitHub Issues](https://github.com/shashank-mugiwara/kittywork/issues)
- **Spring Boot Docs:** https://spring.io/projects/spring-boot
- **Docker Docs:** https://docs.docker.com
- **PostgreSQL Docs:** https://www.postgresql.org/docs/

---

**Last Updated:** January 2025  
**Version:** 1.0.0  
**Maintained By:** Kittywork Team
