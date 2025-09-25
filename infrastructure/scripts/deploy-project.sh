#!/bin/bash
set -euo pipefail

SERVICE_DIR="microservices/ms-doctor"
JAR_NAME="doctor-0.0.1-SNAPSHOT.jar"
PROFILE="aws"

# Move into service folder
cd "$SERVICE_DIR"

# Clean and build the service
echo "Building Doctor microservice..."
mvn clean package -DskipTests

# Find built JAR
TARGET_JAR=$(find target -name "*.jar" | grep "$JAR_NAME" || true)

if [ -z "$TARGET_JAR" ]; then
    echo "Error: JAR file not found in target/. Did the build succeed?"
    exit 1
fi

# Stop any running instance
PID=$(pgrep -f "$JAR_NAME" || true)
if [ -n "$PID" ]; then
    echo "Stopping running Doctor service (PID $PID)..."
    kill -9 "$PID"
fi

# Run the service with AWS profile
echo "Starting Doctor microservice with profile=$PROFILE..."
nohup java -jar "$TARGET_JAR" --spring.profiles.active=$PROFILE > doctor.log 2>&1 &

# Wait a few seconds and confirm
sleep 5
if pgrep -f "$JAR_NAME" > /dev/null; then
    echo "Doctor service started successfully (profile=$PROFILE). Logs: $SERVICE_DIR/doctor.log"
else
    echo "Error: Doctor service failed to start. Check $SERVICE_DIR/doctor.log"
    exit 1
fi