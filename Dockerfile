FROM ghcr.io/graalvm/graalvm-ce:ol8-java17

# Define build arguments with defaults
ARG MIN_MEMORY=1G
ARG MAX_MEMORY=2G
ARG SERVER_PORT=25565
ARG JAVA_VERSION=1.21.0-4

# Set environment variables from build args
ENV MIN_MEMORY=${MIN_MEMORY}
ENV MAX_MEMORY=${MAX_MEMORY}
ENV SERVER_PORT=${SERVER_PORT}
ENV RECOMMENDED_JAVA_VERSION=${JAVA_VERSION}

WORKDIR /data

# Install necessary tools
RUN microdnf install -y wget unzip && \
    microdnf clean all

# Copy the server files to the /data directory, including subdirectories
COPY server_files/ /data/

# Make scripts executable
RUN find /data -type f -name "*.sh" -exec chmod +x {} \;

# Set the entry point to the docker entrypoint script
ENTRYPOINT ["/bin/bash", "/data/docker-entrypoint.sh"]

# Expose the Minecraft server port
EXPOSE ${SERVER_PORT} 