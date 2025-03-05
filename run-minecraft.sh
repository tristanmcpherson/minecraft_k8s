#!/bin/bash
set -e

echo "=== Building and Running Minecraft Server Container ==="
echo

# Check if a container with the same name already exists
if docker ps -a --format '{{.Names}}' | grep -q "^minecraft-server$"; then
  echo "Container 'minecraft-server' already exists. Removing it..."
  docker stop minecraft-server 2>/dev/null || true
  docker rm minecraft-server
  echo "Container removed."
fi

# Build the image
echo "Building the Docker image..."
docker build \
  --build-arg MIN_MEMORY=2G \
  --build-arg MAX_MEMORY=4G \
  --build-arg SERVER_PORT=25565 \
  --build-arg JAVA_VERSION=1.21.0-4 \
  -t minecraft-server:local .

echo
echo "Running the Minecraft server container..."
docker run -d \
  --name minecraft-server \
  -p 25565:25565 \
  -v minecraft_data:/data \
  minecraft-server:local

echo
echo "Container started! You can check the logs with:"
echo "docker logs -f minecraft-server"
echo
echo "To stop the server:"
echo "docker stop minecraft-server"
echo
echo "To remove the container:"
echo "docker rm minecraft-server"
echo
echo "=== Minecraft Server Started ===" 