# hello-streams :arrows_counterclockwise:

## What is this?

`hello-streams` is a demo application presented at [kafka-summit 2019](https://kafka-summit.org/sessions/hello-streams-introducing-stream-first-mindset/) entitled 'hello-streams :: Introducing the "streams-first" mindset'.

## Why make this

To provide insight into an opinionated solution using NodeJS, Java, GraphQL, Kafka, and Kafka-Streams to implement an event-driven-design using event-sourcing, [domain events](https://medium.com/@ha_reneparra/https-medium-com-neoword-domain-events-45697ec0271f), [business events](https://medium.com/homeaway-tech-blog/business-events-in-a-world-of-independently-deployable-services-144daf6caa1a), and [command events](https://medium.com/homeaway-tech-blog/command-events-b8942e251824).

![hello-streams login page](images/hello-streams-01.png)

![streamable coffee shop](images/hello-streams-02.png)

### Pre-Requisites:

**Option 1: Docker (Recommended for quick start)**
- Docker Desktop installed and running
- At least 8GB RAM allocated to Docker
- **No Java or Node.js required on host** - everything runs in containers!

**Option 2: Local Development**
- OpenJDK11 <-- really, you need this!!
- Node + YARN
- docker + docker-compose (for Kafka infrastructure)

## Quick Start with Docker

The easiest way to run the entire stack:

```bash
# First-time initialization (creates topics and schemas)
make docker-init

# Access the Coffee Shop UI at http://localhost:3000
```

See [DOCKER-SETUP.md](./DOCKER-SETUP.md) for detailed Docker instructions and troubleshooting.

## Local Development Setup

### To Build everything:
- Ensure confluent stack is running

```bash
make start-confluent
```

- Build everything

```bash
make build
```

### To Run everything:

- Run each following line in a separate terminal window:
```bash
(cd order-processor && make run)
(cd bean-processor && make run)
(cd barista-processor && make run)
(cd order-cleaner && make run)
(cd coffee-shop-service && make run)
(cd coffee-shop && make run)
```


### TODO

- [x] Build and test run the other services
- [x] Replace ksql stuff with new
	•	cp-ksqldb-server
	•	cp-ksqldb-cli
- [x] Run everything together
- [ ] Observe the connect-datagen thingy
