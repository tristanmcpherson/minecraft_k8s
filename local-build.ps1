Write-Host "=== Minecraft Server Local Build Script ===" -ForegroundColor Cyan
Write-Host "This script mimics the GitHub Actions pipeline to build locally"
Write-Host ""

# Step 1: Find the zip file
Write-Host "Step 1: Finding Minecraft server zip file..." -ForegroundColor Green
$ZIPFILE = Get-ChildItem -Path "minecraft_server" -Filter "*.zip" | Select-Object -First 1 -ExpandProperty FullName

if (-not $ZIPFILE) {
    Write-Host "Error: No zip file found in minecraft_server directory" -ForegroundColor Red
    exit 1
}

Write-Host "Found zip file: $ZIPFILE"
Write-Host ""

# Step 2: Extract the zip file
Write-Host "Step 2: Extracting Minecraft server files..." -ForegroundColor Green
if (Test-Path "server_files") {
    Remove-Item -Path "server_files" -Recurse -Force
}
New-Item -Path "server_files" -ItemType Directory | Out-Null

Expand-Archive -Path $ZIPFILE -DestinationPath "server_files"

Write-Host "Listing extracted files:"
Get-ChildItem -Path "server_files" | Format-Table Name, Length

# Note: We're skipping the server.jar check since start.sh will handle it
Write-Host "Server files extracted successfully"
Write-Host ""

# Step 3: Generate server.properties from config.json
Write-Host "Step 3: Generating server.properties from config.json..." -ForegroundColor Green
if (Test-Path "minecraft_server/config.json") {
    Write-Host "Found config.json, generating server.properties..."
    
    # Check if we can parse JSON
    try {
        $CONFIG = Get-Content -Path "minecraft_server/config.json" -Raw | ConvertFrom-Json
        
        # Extract server properties from config.json
        $PROPERTIES = @()
        foreach ($PROP in $CONFIG.server.properties.PSObject.Properties) {
            $PROPERTIES += "$($PROP.Name)=$($PROP.Value)"
        }
        
        $PROPERTIES | Out-File -FilePath "server_files/server.properties" -Encoding ASCII
        
        Write-Host "server.properties generated successfully"
    } catch {
        Write-Host "Error parsing config.json: $_" -ForegroundColor Red
        exit 1
    }
} else {
    Write-Host "Config file not found, skipping server.properties generation"
}
Write-Host ""

# Step 4: Create docker-entrypoint.sh script
Write-Host "Step 4: Creating docker-entrypoint.sh script..." -ForegroundColor Green
$ENTRYPOINT = @'
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
'@

$ENTRYPOINT | Out-File -FilePath "server_files/docker-entrypoint.sh" -Encoding ASCII
Write-Host "docker-entrypoint.sh created successfully"
Write-Host ""

# Step 5: Extract build args from config
Write-Host "Step 5: Extracting build args from config..." -ForegroundColor Green
if (Test-Path "minecraft_server/config.json") {
    $CONFIG = Get-Content -Path "minecraft_server/config.json" -Raw | ConvertFrom-Json
    $MIN_MEMORY = if ($CONFIG.server.memory.min) { $CONFIG.server.memory.min } else { "1G" }
    $MAX_MEMORY = if ($CONFIG.server.memory.max) { $CONFIG.server.memory.max } else { "2G" }
    $SERVER_PORT = 25565
    
    Write-Host "Extracted memory settings: Min=$MIN_MEMORY, Max=$MAX_MEMORY"
} else {
    Write-Host "Config file not found, using default memory settings"
    $MIN_MEMORY = "1G"
    $MAX_MEMORY = "2G"
    $SERVER_PORT = 25565
}
Write-Host ""

# Step 6: Build Docker image
Write-Host "Step 6: Building Docker image..." -ForegroundColor Green
docker build `
  --build-arg MIN_MEMORY=$MIN_MEMORY `
  --build-arg MAX_MEMORY=$MAX_MEMORY `
  --build-arg SERVER_PORT=$SERVER_PORT `
  -t minecraft-server:local .

Write-Host "Docker image built successfully: minecraft-server:local"
Write-Host ""

# Step 7: Test run the container
Write-Host "Step 7: Test running the container..." -ForegroundColor Green
Write-Host "Starting container in detached mode. Press Ctrl+C to stop watching logs."
Write-Host "The container will be stopped and removed after log display."

$CONTAINER_ID = docker run -d --name minecraft-test -p 25565:25565 minecraft-server:local

# Watch logs for a few seconds
Start-Process -FilePath "docker" -ArgumentList "logs -f $CONTAINER_ID" -NoNewWindow
Start-Sleep -Seconds 10
Stop-Process -Name "docker" -ErrorAction SilentlyContinue

# Clean up
Write-Host ""
Write-Host "Stopping and removing test container..."
docker stop $CONTAINER_ID
docker rm $CONTAINER_ID

Write-Host ""
Write-Host "=== Build and test completed ===" -ForegroundColor Cyan
Write-Host "You can run the container with:"
Write-Host "docker run -d -p 25565:25565 -v minecraft_data:/data minecraft-server:local" 