FROM maven:3.6.3-openjdk-11

WORKDIR /build

# Copy Maven wrapper and pom.xml first for better layer caching
COPY mvnw mvnw.cmd pom.xml ./
COPY .mvn .mvn

# Copy source code
COPY src ./src

# Build and install to local Maven repository
RUN ./mvnw clean install -DskipTests

# This is a build-only image - the artifact is installed in the Maven local repo

