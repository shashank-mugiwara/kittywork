# Multi-stage Dockerfile for Kittywork Spring Boot 3.x Application
# Stage 1: Builder
FROM eclipse-temurin:25-jdk-noble AS builder

WORKDIR /build

# Install Maven
RUN apt-get update && apt-get install -y maven && rm -rf /var/lib/apt/lists/*

# Copy pom.xml and download dependencies (layer caching optimization)
COPY pom.xml .
RUN mvn dependency:go-offline -B

# Copy source code
COPY src ./src

# Build the application
RUN mvn clean package -DskipTests -B

# Stage 2: Runtime
FROM eclipse-temurin:25-jre-noble-chiseled

# Set metadata
LABEL maintainer="Kittywork Team"
LABEL description="Kittywork Job Management and Candidate Application Platform"
LABEL version="1.0.0"

# Create non-root user for security
RUN addgroup --gid 1000 appuser && \
    adduser --uid 1000 --gid 1000 --disabled-password --gecos '' appuser

WORKDIR /app

# Copy built JAR from builder stage
COPY --from=builder --chown=appuser:appuser /build/target/kittywork-*.jar app.jar

# Switch to non-root user
USER appuser

# Expose port
EXPOSE 8080

# Health check using wget (available in chiseled JRE via base image networking tools)
# Alternatively, the app can be checked at the Java level via actuator endpoints
HEALTHCHECK --interval=30s --timeout=10s --start-period=40s --retries=3 \
    CMD wget -q -O- http://localhost:8080/actuator/health/readiness > /dev/null 2>&1 || exit 1

# JVM tuning for containers
# Environment variable expansion in CMD form allows runtime override
ENV JAVA_OPTS="-XX:+UseG1GC -XX:MaxGCPauseMillis=200 -XX:+ParallelRefProcEnabled -Xmx512m -Xms256m"

# Run the application using CMD (not ENTRYPOINT) to allow variable expansion
# The sh -c form enables shell expansion of $JAVA_OPTS at container start time
CMD ["sh", "-c", "exec java ${JAVA_OPTS} -jar app.jar"]
