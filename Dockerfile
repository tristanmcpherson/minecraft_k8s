FROM openjdk:17-slim

WORKDIR /data

# Install necessary tools
RUN apt-get update && \
    apt-get install -y wget unzip && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Copy the extracted server files
COPY server_files/ /data/

# Set the entry point
ENTRYPOINT ["java", "-Xmx2G", "-Xms1G", "-jar", "server.jar", "nogui"]

# Expose the Minecraft server port
EXPOSE 25565 