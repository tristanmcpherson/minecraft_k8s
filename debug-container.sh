#!/bin/bash
set -e

echo "=== Minecraft Server Container Debugging Script ==="
echo

# Build the image
echo "Building the Docker image..."
docker build \
  --build-arg MIN_MEMORY=2G \
  --build-arg MAX_MEMORY=4G \
  --build-arg SERVER_PORT=25565 \
  -t minecraft-server:debug .

echo
echo "Creating a container for inspection with a sleep command instead of the entrypoint..."
CONTAINER_ID=$(docker run -d --entrypoint /bin/bash minecraft-server:debug -c "sleep 300")
echo "Container ID: $CONTAINER_ID"

echo
echo "=== File Structure in Container ==="
echo "Listing root directory:"
docker exec $CONTAINER_ID ls -la /
echo

echo "Listing /data directory:"
docker exec $CONTAINER_ID ls -la /data || echo "Error: /data directory not found or accessible"
echo

echo "Checking for server.jar:"
docker exec $CONTAINER_ID find / -name "server.jar" 2>/dev/null || echo "Error: server.jar not found"
echo

echo "Checking for start.sh:"
docker exec $CONTAINER_ID find / -name "start.sh" 2>/dev/null || echo "Error: start.sh not found"
echo

echo "Checking docker-entrypoint.sh location and permissions:"
docker exec $CONTAINER_ID find / -name "docker-entrypoint.sh" 2>/dev/null
docker exec $CONTAINER_ID ls -la $(docker exec $CONTAINER_ID find / -name "docker-entrypoint.sh" 2>/dev/null | head -1) || echo "Error: docker-entrypoint.sh not found"
echo

echo "Checking server.properties location:"
docker exec $CONTAINER_ID find / -name "server.properties" 2>/dev/null
echo

echo "=== Testing the entrypoint script ==="
echo "Trying to run the entrypoint script manually:"
ENTRYPOINT_PATH=$(docker exec $CONTAINER_ID find / -name "docker-entrypoint.sh" 2>/dev/null | head -1)
if [ -n "$ENTRYPOINT_PATH" ]; then
  docker exec $CONTAINER_ID bash -c "cd /data && bash $ENTRYPOINT_PATH" || echo "Error: Failed to run docker-entrypoint.sh"
else
  echo "Error: docker-entrypoint.sh not found"
fi
echo

echo "Checking for subdirectories in server_files:"
docker exec $CONTAINER_ID find /data -type d | sort

echo
echo "Checking if directories were copied correctly:"
docker exec $CONTAINER_ID ls -la /data/mods || echo "Error: mods directory not found in /data"
docker exec $CONTAINER_ID ls -la /data/config || echo "Error: config directory not found in /data"
echo

echo "Cleaning up the debug container..."
docker stop $CONTAINER_ID
docker rm $CONTAINER_ID

echo
echo "=== Debugging Complete ===" 