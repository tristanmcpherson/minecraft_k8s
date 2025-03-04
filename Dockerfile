FROM openjdk:17-slim

# Define build arguments with defaults
ARG MIN_MEMORY=1G
ARG MAX_MEMORY=2G
ARG SERVER_PORT=25565

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

# Set the entry point with memory settings from build args
ENTRYPOINT ["sh", "-c", "java -Xms${MIN_MEMORY} -Xmx${MAX_MEMORY} -jar server.jar nogui"]

# Expose the Minecraft server port
EXPOSE ${SERVER_PORT} 