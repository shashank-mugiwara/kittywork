# Docker Reference Guide for Kittywork

Quick reference for Docker and Docker Compose commands used with Kittywork.

## Table of Contents

- [Docker Image Management](#docker-image-management)
- [Docker Compose Operations](#docker-compose-operations)
- [Container Inspection](#container-inspection)
- [Networking & Communication](#networking--communication)
- [Volume Management](#volume-management)
- [Performance Tuning](#performance-tuning)
- [Cleanup Commands](#cleanup-commands)

---

## Docker Image Management

### Building Images

```bash
# Build with default tag (latest)
docker build -t kittywork:latest .

# Build with version tag
docker build -t kittywork:v1.0.0 .

# Build with multiple tags
docker build -t kittywork:latest -t kittywork:v1.0.0 .

# Build without cache (forces fresh build)
docker build --no-cache -t kittywork:latest .

# Build with custom Dockerfile
docker build -f Dockerfile.prod -t kittywork:prod .

# Build with build arguments
docker build --build-arg JAVA_VERSION=25 -t kittywork:latest .
```

### Inspecting Images

```bash
# List all local images
docker image ls
docker images

# Show image details (size, created, tags)
docker image inspect kittywork:latest

# View image history and layers
docker history kittywork:latest

# Show image size
docker image ls --format "table {{.Repository}}\t{{.Size}}"

# Search Docker Hub
docker search spring-boot
```

### Tagging & Versioning

```bash
# Tag image for Docker Hub
docker tag kittywork:latest your-username/kittywork:latest
docker tag kittywork:v1.0.0 your-username/kittywork:v1.0.0

# Tag for private registry
docker tag kittywork:latest registry.company.com/kittywork:latest

# Retag existing image
docker tag kittywork:v1.0.0 kittywork:production
```

### Pushing to Registries

```bash
# Docker Hub
docker push your-username/kittywork:latest
docker push your-username/kittywork:v1.0.0

# AWS ECR
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin <account-id>.dkr.ecr.us-east-1.amazonaws.com
docker push <account-id>.dkr.ecr.us-east-1.amazonaws.com/kittywork:latest

# Private registry
docker push registry.company.com/kittywork:latest
```

### Pulling Images

```bash
# Pull latest tag (default)
docker pull your-username/kittywork

# Pull specific version
docker pull your-username/kittywork:v1.0.0

# Pull from private registry
docker pull registry.company.com/kittywork:latest
```

---

## Docker Compose Operations

### Start & Stop Services

```bash
# Start services in foreground
docker compose up

# Start services in background (detached)
docker compose up -d

# Start with fresh build
docker compose up --build

# Start specific service only
docker compose up postgres
docker compose up app

# Stop running services (preserves containers)
docker compose stop

# Stop and remove containers
docker compose down

# Remove everything including volumes
docker compose down -v

# Remove everything including images
docker compose down -v --rmi all
```

### Service Management

```bash
# Restart all services
docker compose restart

# Restart specific service
docker compose restart app

# Pause services (freezes processes)
docker compose pause

# Resume paused services
docker compose unpause

# Kill running containers
docker compose kill

# Force recreate containers
docker compose up -d --force-recreate

# Scale service replicas
docker compose up -d --scale app=3
```

### View Configuration

```bash
# Show effective compose file (after variable substitution)
docker compose config

# Show services
docker compose config --services

# Show volumes
docker compose config --volumes
```

---

## Container Inspection

### Check Status & Logs

```bash
# List running containers
docker compose ps
docker compose ps --all

# Show container status
docker compose status

# View logs (all services)
docker compose logs

# Tail logs from specific service
docker compose logs -f app
docker compose logs -f postgres

# Show last 100 lines
docker compose logs --tail 100 app

# Show logs with timestamps
docker compose logs -t app

# Show logs since specific time
docker compose logs --since 1h app
docker compose logs --since 2025-01-10 app
```

### Access Container Shell

```bash
# Execute bash in running container
docker compose exec app bash
docker exec kittywork-app bash

# Run command in container
docker compose exec app ls -la /app

# Execute as root user
docker compose exec -u root app bash

# Execute PostgreSQL command
docker compose exec postgres psql -U kittywork -d kittywork -c "SELECT * FROM jobs;"

# Interactive Python shell
docker compose exec postgres python3
```

### Container Resource Usage

```bash
# Real-time resource monitoring
docker stats

# Show memory and CPU limits
docker stats --no-stream

# Inspect specific container
docker stats kittywork-app

# See container resource limits
docker inspect kittywork-app | grep -A 20 '"HostConfig"'
```

### Container Information

```bash
# Show container details
docker inspect kittywork-app

# Show specific field
docker inspect -f '{{.NetworkSettings.Networks.kittywork-network.IPAddress}}' kittywork-app

# Show environment variables
docker inspect -f '{{json .Config.Env}}' kittywork-app | jq

# Show mounted volumes
docker inspect -f '{{json .Mounts}}' kittywork-app | jq
```

---

## Networking & Communication

### Inspect Networks

```bash
# List networks
docker network ls

# Show network details
docker network inspect kittywork-network

# Connect container to network
docker network connect kittywork-network container-name

# Disconnect container from network
docker network disconnect kittywork-network container-name
```

### Test Connectivity

```bash
# From app container, test database connection
docker compose exec app curl -v telnet postgres:5432

# From app container, test S3
docker compose exec app aws s3 ls s3://kittywork-resumes-prod/

# DNS resolution
docker compose exec app nslookup postgres

# Ping database
docker compose exec app ping postgres
```

### Port Mapping

```bash
# Show port mappings
docker compose ps

# Detailed port info
docker compose port app 8080
docker compose port postgres 5432

# Forward specific port to host
docker run -p 8080:8080 kittywork:latest
docker run -p 9000:8080 kittywork:latest  # Map host:9000 -> container:8080
```

---

## Volume Management

### Volume Operations

```bash
# List volumes
docker volume ls

# Show volume details
docker volume inspect postgres_data

# View volume mount point on host
docker inspect -f '{{json .Mounts}}' kittywork-db

# Copy data from container to host
docker cp kittywork-app:/app/logs ./logs_backup

# Copy data from host to container
docker cp ./uploads kittywork-app:/app/
```

### Backup & Restore

```bash
# Backup PostgreSQL volume
docker run --rm -v postgres_data:/data -v $(pwd):/backup \
  postgres:16-alpine tar czf /backup/postgres_backup.tar.gz /data

# Restore PostgreSQL volume
docker run --rm -v postgres_data:/data -v $(pwd):/backup \
  postgres:16-alpine tar xzf /backup/postgres_backup.tar.gz

# Backup using postgres dump
docker compose exec postgres pg_dump -U kittywork kittywork > db_backup.sql

# Restore from dump
docker compose exec -T postgres psql -U kittywork kittywork < db_backup.sql
```

---

## Performance Tuning

### Memory Management

```bash
# Check current memory usage
docker stats --no-stream kittywork-app

# Set memory limits in docker-compose.yml
# services:
#   app:
#     deploy:
#       resources:
#         limits:
#           memory: 1G
#         reservations:
#           memory: 512M

# Adjust JVM heap
# Set JAVA_OPTS in .env
JAVA_OPTS=-Xmx1024m -Xms512m -XX:+UseG1GC
```

### CPU Management

```bash
# View CPU usage
docker stats kittywork-app

# Set CPU limits
# services:
#   app:
#     deploy:
#       resources:
#         limits:
#           cpus: '1.0'
#         reservations:
#           cpus: '0.5'

# View CPU throttling
docker stats --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}"
```

### Disk I/O

```bash
# Monitor disk I/O
docker stats --format "table {{.Container}}\t{{.BlockIO}}"

# Check disk usage of volumes
du -sh $(docker inspect postgres_data -f '{{.Mountpoint}}')

# Optimize images (remove unnecessary layers)
docker image prune -a --filter "until=72h"
```

---

## Cleanup Commands

### Remove Containers

```bash
# Remove stopped containers
docker container prune

# Force remove container
docker rm -f kittywork-app

# Remove all containers
docker container prune --all
```

### Remove Images

```bash
# Remove image
docker rmi kittywork:latest

# Force remove image
docker rmi -f kittywork:latest

# Remove dangling images (untagged)
docker image prune

# Remove unused images
docker image prune -a --filter "until=720h"
```

### Remove Volumes

```bash
# Remove unused volumes
docker volume prune

# Force remove volume
docker volume rm postgres_data

# Remove all volumes (CAREFUL!)
docker volume prune --all
```

### Full Cleanup

```bash
# Remove all stopped containers, networks, images, and volumes
docker system prune -a --volumes

# Show what would be removed without removing
docker system prune --all --dry-run
```

---

## Troubleshooting Commands

### Diagnose Issues

```bash
# Check Docker daemon status
docker info

# View system events in real-time
docker events

# Check for errors in service
docker compose logs app 2>&1 | grep -i error

# Validate docker-compose.yml
docker compose config

# Test service connectivity
docker compose exec app curl -v http://postgres:5432
```

### Debug Container

```bash
# Run container with debugging
docker compose exec app bash
docker compose exec app set -x  # Enable debug output

# Check environment
docker compose exec app env | sort

# Check filesystem
docker compose exec app ls -la /app
docker compose exec app du -sh /app/*

# Monitor processes
docker compose exec app ps aux
```

### Network Debugging

```bash
# Check container IP
docker inspect -f '{{.NetworkSettings.Networks.kittywork-network.IPAddress}}' kittywork-app

# Test DNS
docker compose exec app cat /etc/resolv.conf

# Show listening ports
docker compose exec app ss -tlnp

# Test external connectivity
docker compose exec app curl -I https://aws.amazon.com
```

---

## Advanced Usage

### Custom Build with Arguments

```bash
# Dockerfile
ARG JAVA_VERSION=25
FROM eclipse-temurin:${JAVA_VERSION}-jre-noble-chiseled

# Build with custom Java version
docker build --build-arg JAVA_VERSION=25 -t kittywork:java25 .
```

### Multi-Host Compose (Swarm)

```bash
# Initialize Docker Swarm
docker swarm init

# Deploy stack
docker stack deploy -c docker-compose.yml kittywork

# List stacks
docker stack ls

# Remove stack
docker stack rm kittywork
```

### Health Check Scripting

```bash
# Create health check function
health_check() {
  curl -f http://localhost:8080/actuator/health || return 1
}

# Monitor until healthy
until health_check; do
  echo "Waiting for service..."
  sleep 5
done

echo "Service is healthy!"
```

---

## Environment Variable Injection

### Using .env File

```bash
# docker-compose.yml recognizes .env automatically
# Format: KEY=VALUE

# Override specific variables
docker compose --env-file .env.prod up

# Pass inline
docker compose -e DB_PASSWORD=new_password up
```

### Variable Substitution

```bash
# In docker-compose.yml
environment:
  DB_PASSWORD: ${DB_PASSWORD:-default_password}
  DB_HOST: ${DB_HOST}
  APP_PORT: ${APP_PORT:-8080}

# Variables are substituted at runtime
```

---

## Performance Checklist

- [ ] Use multi-stage builds to reduce image size
- [ ] Use minimal base images (alpine, chiseled)
- [ ] Layer caching: dependencies before code
- [ ] Set resource limits and requests
- [ ] Use health checks for readiness/liveness
- [ ] Configure logging drivers
- [ ] Monitor container resource usage regularly
- [ ] Clean up unused images, containers, volumes
- [ ] Use volume drivers appropriate for workload
- [ ] Implement proper networking policies

---

**For more information, see:**
- [Docker CLI Reference](https://docs.docker.com/engine/reference/commandline/)
- [Docker Compose Reference](https://docs.docker.com/compose/compose-file/)
- [DEPLOYMENT.md](../DEPLOYMENT.md)
