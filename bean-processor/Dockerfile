FROM maven:3.6.3-openjdk-11

WORKDIR /workspace

# First, build and install stream-models dependency
COPY stream-models/pom.xml ./stream-models/
COPY stream-models/src ./stream-models/src

# Use Maven directly instead of wrapper since we're in a Maven container
RUN cd stream-models && mvn clean install -DskipTests

# Now build bean-processor
WORKDIR /workspace/bean-processor

# Copy pom.xml first for better layer caching
COPY bean-processor/pom.xml ./

# Copy source code
COPY bean-processor/src ./src

# Build the application using Maven directly
RUN mvn clean install -DskipTests

# The JAR file should now be in target/
RUN ls -la target/

# Optional: Set the command to run the application (can be overridden)
CMD ["sh", "-c", "java -jar target/bean-processor-*-SNAPSHOT.jar"]

