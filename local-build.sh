#!/bin/bash
set -e

echo "=== Minecraft Server Local Build Script ==="
echo "This script mimics the GitHub Actions pipeline to build locally"
echo

# Step 1: Find the zip file
echo "Step 1: Finding Minecraft server zip file..."
ZIPFILE=$(find minecraft_server -name "*.zip" | head -n 1)

if [ -z "$ZIPFILE" ]; then
  echo "Error: No zip file found in minecraft_server directory"
  exit 1
fi

echo "Found zip file: $ZIPFILE"
echo

# Step 2: Extract the zip file
echo "Step 2: Extracting Minecraft server files..."
rm -rf server_files
mkdir -p server_files

unzip "$ZIPFILE" -d server_files

echo "Listing extracted files:"
ls -la server_files/

# Note: We're skipping the server.jar check since start.sh will handle it
echo "Server files extracted successfully"
echo

# Step 3: Generate server.properties from config.json
echo "Step 3: Generating server.properties from config.json..."
if [ -f "minecraft_server/config.json" ]; then
  echo "Found config.json, generating server.properties..."
  
  # Check if jq is installed
  if ! command -v jq &> /dev/null; then
    echo "Error: jq is not installed. Please install it to continue."
    exit 1
  fi
  
  # Extract server properties from config.json
  jq -r '.server.properties | to_entries | map("\(.key)=\(.value)") | .[]' minecraft_server/config.json > server_files/server.properties
  
  echo "server.properties generated successfully"
else
  echo "Config file not found, skipping server.properties generation"
fi
echo

# Step 4: Create docker-entrypoint.sh script
echo "Step 4: Creating docker-entrypoint.sh script..."
cat > server_files/docker-entrypoint.sh << 'EOF'
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
fi
EOF

chmod +x server_files/docker-entrypoint.sh
echo "docker-entrypoint.sh created successfully"
echo

# Step 5: Extract build args from config
echo "Step 5: Extracting build args from config..."
if [ -f "minecraft_server/config.json" ]; then
  MIN_MEMORY=$(jq -r '.server.memory.min // "1G"' minecraft_server/config.json)
  MAX_MEMORY=$(jq -r '.server.memory.max // "2G"' minecraft_server/config.json)
  SERVER_PORT=25565
  
  echo "Extracted memory settings: Min=$MIN_MEMORY, Max=$MAX_MEMORY"
else
  echo "Config file not found, using default memory settings"
  MIN_MEMORY="1G"
  MAX_MEMORY="2G"
  SERVER_PORT=25565
fi
echo

# Step 6: Build Docker image
echo "Step 6: Building Docker image..."
docker build \
  --build-arg MIN_MEMORY=$MIN_MEMORY \
  --build-arg MAX_MEMORY=$MAX_MEMORY \
  --build-arg SERVER_PORT=$SERVER_PORT \
  -t minecraft-server:local .

echo "Docker image built successfully: minecraft-server:local"
echo

# Step 7: Test run the container
echo "Step 7: Test running the container..."
echo "Starting container in detached mode. Press Ctrl+C to stop watching logs."
echo "The container will be stopped and removed after log display."

CONTAINER_ID=$(docker run -d --name minecraft-test -p 25565:25565 minecraft-server:local)

# Watch logs for a few seconds
docker logs -f $CONTAINER_ID &
LOGS_PID=$!

# Wait for 10 seconds or until user presses Ctrl+C
sleep 10
kill $LOGS_PID 2>/dev/null || true

# Clean up
echo
echo "Stopping and removing test container..."
docker stop $CONTAINER_ID
docker rm $CONTAINER_ID

echo
echo "=== Build and test completed ==="
echo "You can run the container with:"
echo "docker run -d -p 25565:25565 -v minecraft_data:/data minecraft-server:local" 