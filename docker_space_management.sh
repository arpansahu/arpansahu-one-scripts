#!/bin/bash

LOG_FILE="/root/logs/docker_space_management.log"

# Log the current time and date
echo "Docker Space Management Process Started at $(date)" >> $LOG_FILE

# 0. Check System Size
echo "Checking current system disk usage..." >> $LOG_FILE
df -h >> $LOG_FILE

# 1. Check Docker Space Usage
echo "Checking Docker disk usage..." >> $LOG_FILE
docker system df -v >> $LOG_FILE

# 2. Identify the Largest Volume
LARGEST_VOLUME=$(docker system df -v | grep -E '^VOLUME NAME' -A 1 | tail -n 1 | awk '{print $1}')
if [ -z "$LARGEST_VOLUME" ]; then
    echo "No volumes found. Exiting..." >> $LOG_FILE
    exit 1
fi

echo "Largest volume identified: $LARGEST_VOLUME" >> $LOG_FILE

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
docker exec $CONTAINER_ID sh -c "
    cd /var/lib/containerd/io.containerd.snapshotter.v1.overlayfs/snapshots/ && \
    rm -rf * && \
    crictl rmi --prune
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
