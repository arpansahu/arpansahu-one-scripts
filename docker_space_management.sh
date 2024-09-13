#!/bin/bash

LOG_FILE="/var/log/docker_space_management.log"

# Log the current time and date
echo "Docker Space Management Process Started at $(date)" >> $LOG_FILE

# 0. Check System Size
echo "Checking current system disk usage..." >> $LOG_FILE
df -h >> $LOG_FILE

# 1. Check Docker Space Usage
echo "Checking Docker disk usage..." >> $LOG_FILE
docker system df -v >> $LOG_FILE

# 2. Identify the Largest Volume

# Extract volume data, sort by size, and pick the largest one
LARGEST_VOLUME=$(docker system df -v | awk '/VOLUME NAME/{getline; print $1, $3}' | sort -k2 -rh | head -n 1 | awk '{print $1}')
LARGEST_VOLUME_SIZE=$(docker system df -v | awk '/VOLUME NAME/{getline; print $1, $3}' | sort -k2 -rh | head -n 1 | awk '{print $2}')

if [ -z "$LARGEST_VOLUME" ]; then
    echo "No volumes found. Exiting..." >> $LOG_FILE
    exit 1
fi

echo "Largest volume identified: $LARGEST_VOLUME (Size: $LARGEST_VOLUME_SIZE)" >> $LOG_FILE

# Find the container associated with the largest volume
CONTAINER_ID=$(docker ps -a --filter "volume=$LARGEST_VOLUME" --format "{{.ID}}")
CONTAINER_NAME=$(docker ps -a --filter "volume=$LARGEST_VOLUME" --format "{{.Names}}")
if [ -z "$CONTAINER_ID" ]; then
    echo "No container found using the largest volume. Exiting..." >> $LOG_FILE
    exit 1
fi

echo "Container using the largest volume: $CONTAINER_NAME ($CONTAINER_ID)" >> $LOG_FILE

# 3. Access the Docker Container and perform cleanup
echo "Attempting to perform cleanup in container $CONTAINER_NAME..." >> $LOG_FILE

# Ensure correct directory exists before attempting to clean up
docker exec $CONTAINER_ID sh -c "
    if [ -d /var/lib/containerd/io.containerd.snapshotter.v1.overlayfs/snapshots/ ]; then
        cd /var/lib/containerd/io.containerd.snapshotter.v1.overlayfs/snapshots/ && rm -rf *
        crictl rmi --prune
    else
        echo 'Directory not found, skipping cleanup.'
    fi
" >> $LOG_FILE 2>&1

if [ $? -eq 0 ]; then
    echo "Cleanup completed successfully in container $CONTAINER_NAME." >> $LOG_FILE
else
    echo "Failed to clean up container $CONTAINER_NAME." >> $LOG_FILE
fi

# 7. Recheck System Size
echo "Rechecking system disk usage..." >> $LOG_FILE
df -h >> $LOG_FILE

# Log completion time
echo "Docker Space Management Process Completed at $(date)" >> $LOG_FILE
