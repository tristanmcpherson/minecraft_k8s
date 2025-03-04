#!/bin/bash
set -e

# Print Minecraft server version
echo "Starting Minecraft server with the following settings:"
echo "Memory: ${MIN_MEMORY} - ${MAX_MEMORY}"
echo "Server properties loaded from: /data/server.properties"

# Accept EULA if not already accepted
if [ ! -f "/data/eula.txt" ] || ! grep -q "eula=true" "/data/eula.txt"; then
  echo "Accepting Minecraft EULA..."
  echo "eula=true" > /data/eula.txt
fi

# Set memory settings in environment for the start.sh script to use
export JAVA_OPTS="-Xms${MIN_MEMORY} -Xmx${MAX_MEMORY}"

# Check if start.sh exists
if [ -f "/data/start.sh" ]; then
  echo "Found start.sh script, executing..."
  chmod +x /data/start.sh
  exec /data/start.sh
else
  echo "No start.sh found, falling back to direct Java execution"
  
  # Check if server.jar exists
  if [ ! -f "/data/server.jar" ]; then
    echo "Error: server.jar not found!"
    exit 1
  fi
  
  # Start the Minecraft server directly
  echo "Starting Minecraft server..."
  exec java -Xms${MIN_MEMORY} -Xmx${MAX_MEMORY} -jar server.jar nogui 