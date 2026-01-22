# Docker Setup for Hello Streams

This document describes the Docker setup for running the entire Hello Streams application stack.

## Overview

All microservices and infrastructure components have been containerized and can be run using Docker Compose.

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                    Hello Streams Docker Stack                    │
├─────────────────────────────────────────────────────────────────┤
│                                                                   │
│  ┌──────────────┐        ┌──────────────┐                       │
│  │  Coffee Shop │───────▶│  Coffee Shop │                       │
│  │  (React UI)  │        │   Service    │                       │
│  │  Port 3000   │        │  (GraphQL)   │                       │
│  └──────────────┘        │  Port 4000   │                       │
│                          └──────┬───────┘                        │
│                                 │                                │
│        ┌────────────────────────┴────────────────────┐          │
│        ▼                        ▼                     ▼          │
│  ┌──────────┐         ┌──────────────┐      ┌────────────┐     │
│  │  Order   │         │     Bean     │      │  Barista   │     │
│  │Processor │         │  Processor   │      │ Processor  │     │
│  │Port 5001 │         │  Port 5100   │      │ Port 5200  │     │
│  └────┬─────┘         └──────┬───────┘      └─────┬──────┘     │
│       │                      │                    │             │
│       │       ┌──────────────┴────────────┐       │             │
│       │       │    Order Cleaner          │       │             │
│       │       │      Port 5300            │       │             │
│       │       └───────────┬───────────────┘       │             │
│       └───────────────────┼───────────────────────┘             │
│                           │                                     │
│         ┌─────────────────┴──────────────────┐                 │
│         ▼                                     ▼                 │
│  ┌──────────┐    ┌────────────┐    ┌───────────────┐          │
│  │  Kafka   │    │  Zookeeper │    │Schema Registry│          │
│  │Port 9092 │    │ Port 2181  │    │   Port 8081   │          │
│  └──────────┘    └────────────┘    └───────────────┘          │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

## Services

### Infrastructure (Confluent Stack)
- **Zookeeper**: Coordination service (port 2181)
- **Kafka Broker**: Message broker (ports 9092, 29092)
- **Schema Registry**: Avro schema management (port 8081)

### Java Microservices (Spring Boot + Kafka Streams)
- **order-processor**: Handles order processing (port 5001) *Note: Changed from 5000 due to macOS port conflict*
- **bean-processor**: Manages coffee bean inventory (port 5100)
- **barista-processor**: Processes barista actions (port 5200)
- **order-cleaner**: Cleans up old orders (port 5300)

### Node.js Services
- **coffee-shop-service**: GraphQL backend service (port 4000)
- **coffee-shop**: React frontend UI (port 3000)

## Prerequisites

- Docker Desktop installed and running
- At least 8GB RAM allocated to Docker
- Ports 2181, 3000, 4000, 5001, 5100, 5200, 5300, 8081, 9092, 29092 available

**Note:** Java is NOT required on your host machine - all Java operations run inside Docker containers.

## Quick Start

### First-Time Setup

For a **fresh installation**, use the initialization command which sets up topics and schemas:

```bash
# Initialize everything (first time only)
make docker-init
```

This command will:
1. Start all Docker services
2. Wait for Kafka and Schema Registry to be ready
3. Run a containerized Maven build to create Kafka topics and register schemas
4. Create required Kafka topics (`order-command-events`, `orders`, `bean-command-events`, `beans`)
5. Register Avro schemas with the Schema Registry
6. Restart microservices to initialize Kafka Streams state stores
7. Wait for services to fully initialize

**Note:** 
- The initialization process takes ~2-3 minutes total. Wait for the "✓ Initialization complete!" message before accessing the application.
- No host Java installation required - everything runs in Docker containers.

### Regular Use

After the first-time setup, use these commands for day-to-day operations:

```bash
# Start all services
make docker-up

# Stop all services
make docker-down

# View logs
make docker-logs

# Check service status
make docker-ps

# Restart services
make docker-restart

# Clean up everything (including volumes)
make docker-clean
```

**Important:** If you run `make docker-clean`, you'll need to run `make docker-init` again to recreate topics and schemas.

### Using Docker Compose Directly

If you prefer to use Docker Compose commands directly:

```bash
# First-time setup
docker-compose up -d
# Wait ~60 seconds for Kafka to be ready, then:
docker-compose run --rm stream-init
# Restart microservices to initialize state stores:
docker-compose restart order-processor bean-processor barista-processor order-cleaner
# Wait ~60 seconds for services to initialize

# Regular operations
docker-compose up -d              # Start services
docker-compose down               # Stop services
docker-compose logs -f [service]  # View logs
docker-compose ps                 # Check status
docker-compose build [service]    # Rebuild images
docker-compose restart [service]  # Restart service
```

**Note:** 
- The `stream-init` service runs Maven in a container, so you don't need Java installed on your host machine.
- After creating topics, microservices must be restarted to initialize their Kafka Streams state stores.

## Docker Images Built

All services have been containerized with the following images:

| Service | Image | Size | Base Image |
|---------|-------|------|------------|
| order-processor | `order-processor:latest` | 923 MB | maven:3.6.3-openjdk-11 |
| bean-processor | `bean-processor:latest` | 923 MB | maven:3.6.3-openjdk-11 |
| barista-processor | `barista-processor:latest` | 923 MB | maven:3.6.3-openjdk-11 |
| order-cleaner | `order-cleaner:latest` | 923 MB | maven:3.6.3-openjdk-11 |
| coffee-shop-service | `coffee-shop-service:latest` | 952 MB | node:12 |
| coffee-shop | `coffee-shop:latest` | 1.33 GB | node:12 |

## Configuration

### Java Services

Java services are configured to use Docker networking via Java system properties:

```yaml
environment:
  JAVA_OPTS: >
    -D[service].bootstrap.servers=PLAINTEXT://broker:9092
    -D[service].schema.registry.url=http://schema-registry:8081
```

Services connect to:
- **Kafka**: `broker:9092` (internal Docker network)
- **Schema Registry**: `http://schema-registry:8081`

### Node.js Services

- **coffee-shop-service**: Connects to Java processors via Docker service names
- **coffee-shop**: Configured with `SKIP_PREFLIGHT_CHECK=true` for webpack compatibility

## Networking

All services run on a dedicated Docker bridge network: `hello-streams-network`

This allows services to communicate using service names as hostnames:
- `broker` instead of `localhost:9092`
- `schema-registry` instead of `localhost:8081`
- `order-processor` instead of `localhost:5000`

## Port Mapping

External access to services:

| Service | Internal Port | External Port | URL |
|---------|---------------|---------------|-----|
| Coffee Shop UI | 3000 | 3000 | http://localhost:3000 |
| Coffee Shop Service | 4000 | 4000 | http://localhost:4000 |
| Order Processor | 5000 | 5001 | http://localhost:5001 |
| Bean Processor | 5100 | 5100 | http://localhost:5100 |
| Barista Processor | 5200 | 5200 | http://localhost:5200 |
| Order Cleaner | 5300 | 5300 | http://localhost:5300 |
| Schema Registry | 8081 | 8081 | http://localhost:8081 |
| Kafka Broker | 9092 | 29092 | localhost:29092 |

## Troubleshooting

### "Add 10 Beans" Button Not Working / State Store Errors

**Symptoms:** GraphQL errors about state stores ("may have migrated to another instance"), bean count stays at 0, orders not processing.

**Cause:** Kafka topics and schemas were not properly initialized.

**Solution:**
```bash
# Run the containerized initialization
docker-compose run --rm stream-init

# Then restart the services
docker-compose restart bean-processor order-processor barista-processor order-cleaner
```

### Missing Kafka Topics

If you see errors about missing topics, create them:
```bash
# List existing topics
docker exec broker kafka-topics --bootstrap-server localhost:9092 --list

# If topics are missing, run the initialization:
docker-compose run --rm stream-init
```

### Java Version Issues on Host

If you see Maven errors about "invalid target release: 11", don't worry! The new Docker-based initialization doesn't require Java on your host machine. Just use:

```bash
make docker-init
# or
docker-compose run --rm stream-init
```

Both commands run Maven inside a Docker container with Java 11 pre-installed.

### Port 5000 Conflict (macOS)
macOS Control Center uses port 5000. The order-processor has been remapped to port 5001.

### Coffee Shop UI Not Starting
The React dev server may exit immediately. Restart it:
```bash
docker-compose restart coffee-shop
```

### Java Services Not Connecting to Kafka
Check Kafka is ready:
```bash
docker logs broker | grep "started (kafka.server.KafkaServer)"
```

### Viewing Service Logs
```bash
# All services
docker-compose logs -f

# Specific service
docker logs <service-name> -f
```

### Restarting a Single Service
```bash
docker-compose restart <service-name>
```

### Starting Fresh

To completely reset the environment:
```bash
make docker-clean    # Removes all containers, networks, and volumes
make docker-init     # Reinitialize from scratch
```

## Development Workflow

### Building Individual Services
```bash
# Rebuild a specific service
docker-compose build <service-name>

# Rebuild and restart
docker-compose up -d --build <service-name>
```

### Accessing Services
- **Web UI**: http://localhost:3000
- **GraphQL Playground**: http://localhost:4000
- **Processor GraphQL**: http://localhost:5001/graphql (order), 5100 (bean), 5200 (barista)

## Notes

- All Java services use OpenJDK 11 as required by the project
- Services are configured with proper dependency ordering via `depends_on`
- No local Java or Node.js installation required
- Build times are cached for faster subsequent builds
- Platform warning (AMD64 on ARM64) is expected on M1/M2 Macs and works via emulation
- The `stream-init` service temporarily modifies `stream-registration.yaml` to use Docker network hostnames. If you need to run the local version later, restore it with: `git checkout stream-models/src/main/resources/stream-registration.yaml`

## Cleaning Up

```bash
# Stop and remove containers
make docker-down

# Remove all containers, networks, and images
make docker-clean

# Remove individual stopped containers
docker-compose rm <service-name>
```

