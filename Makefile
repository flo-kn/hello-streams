.PHONY: start-confluent register-streams build stop-confluent reset-processors delete-topics reset
.PHONY: docker-build docker-up docker-down docker-logs docker-ps docker-restart docker-clean

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

# Start everything (infrastructure + services)
docker-start-all: docker-up
	echo "All services started! Access the coffee shop at http://localhost:3000"

# Stop everything
docker-stop-all: docker-down
	echo "All services stopped"
