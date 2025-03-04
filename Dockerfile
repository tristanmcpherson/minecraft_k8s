FROM openjdk:17-slim

# Define build arguments with defaults
ARG MIN_MEMORY=1G
ARG MAX_MEMORY=2G
ARG SERVER_PORT=25565

# Set environment variables from build args
ENV MIN_MEMORY=${MIN_MEMORY}
ENV MAX_MEMORY=${MAX_MEMORY}
ENV SERVER_PORT=${SERVER_PORT}

WORKDIR /data

# Install necessary tools
RUN apt-get update && \
    apt-get install -y wget unzip && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Copy the extracted server files
COPY server_files/ /data/

# Copy server.properties if it exists
COPY server_files/server.properties /data/server.properties

# Copy and make the docker entrypoint script executable
COPY server_files/docker-entrypoint.sh /data/docker-entrypoint.sh
RUN chmod +x /data/docker-entrypoint.sh

# Set the entry point to the docker entrypoint script
ENTRYPOINT ["/data/docker-entrypoint.sh"]

# Expose the Minecraft server port
EXPOSE ${SERVER_PORT} 