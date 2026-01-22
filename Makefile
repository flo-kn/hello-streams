.PHONY: start-confluent register-streams build stop-confluent reset-processors delete-topics reset
.PHONY: docker-build docker-up docker-down docker-logs docker-ps docker-restart docker-clean docker-init

start-confluent:
	echo "starting confluent stack..."
	(cd confluent-stack && make start)

register-streams:
	echo "Registering streams and schemas..."
	(cd stream-models && make build)

build:
	echo "Building order-processor..."
	(cd order-processor && make build)
	echo "Building bean-processor..."
	(cd bean-processor && make build)
	echo "Building barista-processor..."
	(cd barista-processor && make build)
	echo "Building order-cleaner..."
	(cd order-cleaner && make build)

stop-confluent:
	echo "stopping confluent stack..."
	(cd confluent-stack && make stop)

reset-processors:
	echo "Resetting order-processor"
	kafka-streams-application-reset --application-id order-processor --bootstrap-servers localhost:9092 --to-earliest --execute
	echo "Resetting bean-processor"
	kafka-streams-application-reset --application-id bean-processor --bootstrap-servers localhost:9092 --to-earliest --execute
	echo "Resetting barista-processor"
	kafka-streams-application-reset --application-id barista-processor --bootstrap-servers localhost:9092 --to-earliest --execute
	echo "Resetting order-cleaner"
	kafka-streams-application-reset --application-id order-cleaner --bootstrap-servers localhost:9092 --to-earliest --execute
	echo "Resetting local rocksDB"
	rm -rf /tmp/kafka-streams/

delete-topics:
	echo "Deleting beans topic"
	kafka-topics --bootstrap-server localhost:9092 --topic beans --delete
	echo "Deleting bean-command-events topic"
	kafka-topics --bootstrap-server localhost:9092 --topic bean-command-events --delete
	echo "Deleting orders topic"
	kafka-topics --bootstrap-server localhost:9092 --topic orders --delete
	echo "Deleting order-command-events topic"
	kafka-topics --bootstrap-server localhost:9092 --topic order-command-events --delete

reset: reset-processors delete-topics register-streams

# Docker Compose targets
docker-build:
	echo "Building all Docker images..."
	docker-compose build

docker-up:
	echo "Starting all services with Docker Compose..."
	docker-compose up -d

docker-down:
	echo "Stopping all services..."
	docker-compose down

docker-logs:
	docker-compose logs -f

docker-ps:
	docker-compose ps

docker-restart:
	echo "Restarting all services..."
	docker-compose restart

docker-clean:
	echo "Stopping and removing all containers, networks, and volumes..."
	docker-compose down -v
	docker system prune -f

# Initialize Docker environment (first-time setup)
# Uses containerized Maven - no host Java installation required
docker-init:
	@echo "=========================================="
	@echo "Initializing Hello Streams Docker Stack"
	@echo "=========================================="
	@echo "Step 1: Starting Docker services..."
	docker-compose up -d
	@echo ""
	@echo "Step 2: Waiting for Kafka and Schema Registry to be ready..."
	@echo "This may take 30-60 seconds..."
	@timeout=60; \
	while [ $$timeout -gt 0 ]; do \
		if docker exec broker kafka-broker-api-versions --bootstrap-server broker:9092 > /dev/null 2>&1 && \
		   curl -sf http://localhost:8081/ > /dev/null 2>&1; then \
			echo "✓ Infrastructure is ready!"; \
			break; \
		fi; \
		echo "  Waiting... ($$timeout seconds remaining)"; \
		sleep 5; \
		timeout=$$((timeout - 5)); \
	done
	@echo ""
	@echo "Step 3: Creating Kafka topics and registering schemas..."
	@echo "(Running in Docker container - no host Java required)"
	docker-compose run --rm stream-init
	@echo ""
	@echo "Step 4: Restarting microservices to initialize state stores..."
	docker-compose restart order-processor bean-processor order-cleaner
	@echo "Waiting a moment for order-processor to create its changelog topic..."
	@sleep 10
	@echo "Restarting barista-processor (depends on order-processor changelog)..."
	docker-compose restart barista-processor
	@echo ""
	@echo "Step 5: Waiting for microservices to initialize (~60 seconds)..."
	@echo "This allows Kafka Streams state stores to be created."
	@sleep 60
	@echo "✓ Microservices should be ready!"
	@echo ""
	@echo "=========================================="
	@echo "✓ Initialization complete!"
	@echo "=========================================="
	@echo "Access the Coffee Shop UI at: http://localhost:3000"
	@echo ""
	@echo "To view logs: make docker-logs"
	@echo "To stop:      make docker-down"
	@echo "=========================================="

# Start everything (infrastructure + services)
docker-start-all: docker-up
	echo "All services started! Access the coffee shop at http://localhost:3000"

# Stop everything
docker-stop-all: docker-down
	echo "All services stopped"
