FROM openjdk:17-slim

WORKDIR /data

# Install necessary tools
RUN apt-get update && \
    apt-get install -y wget unzip && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Copy the Minecraft server zip file
COPY minecraft_server/minecraft_server.zip /tmp/

# Extract the server
RUN unzip /tmp/minecraft_server.zip -d /data && \
    rm /tmp/minecraft_server.zip

# Set the entry point
ENTRYPOINT ["java", "-Xmx2G", "-Xms1G", "-jar", "server.jar", "nogui"]

# Expose the Minecraft server port
EXPOSE 25565 