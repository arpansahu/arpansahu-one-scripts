#!/bin/bash

# Log the current time and date
echo "Docker Space Management Process Started at $(date)" >> /var/log/docker_space_management.log

# 0. Check System Size
echo "Checking current system disk usage..." >> /var/log/docker_space_management.log
df -h >> /var/log/docker_space_management.log

# 1. Check Docker Space Usage
echo "Checking Docker disk usage..." >> /var/log/docker_space_management.log
docker system df -v >> /var/log/docker_space_management.log

# 2. Identify the Largest Volume
LARGEST_VOLUME=$(docker system df -v | grep -E '^VOLUME NAME' -A 1 | tail -n 1 | awk '{print $1}')
echo "Largest volume identified: $LARGEST_VOLUME" >> /var/log/docker_space_management.log

# Find the container associated with the largest volume
CONTAINER_ID=$(docker ps -a --filter "volume=$LARGEST_VOLUME" --format "{{.ID}}")
CONTAINER_NAME=$(docker ps -a --filter "volume=$LARGEST_VOLUME" --format "{{.Names}}")
echo "Container using the largest volume: $CONTAINER_NAME ($CONTAINER_ID)" >> /var/log/docker_space_management.log

# 3. Access the Docker Container and perform cleanup
if [ -n "$CONTAINER_ID" ]; then
    echo "Accessing container $CONTAINER_NAME and performing cleanup..." >> /var/log/docker_space_management.log
    docker exec -it $CONTAINER_ID sh -c "
        echo 'Navigating to snapshots directory...'
        cd /var/lib/containerd/io.containerd.snapshotter.v1.overlayfs/snapshots/
        
        echo 'Removing all snapshots...'
        rm -rf *
        
        echo 'Cleaning up unused images...'
        crictl rmi --prune
        
        echo 'Cleanup completed inside container.'
    " >> /var/log/docker_space_management.log
else
    echo "No container found using the largest volume. Skipping container cleanup." >> /var/log/docker_space_management.log
fi

# 7. Recheck System Size
echo "Rechecking system disk usage..." >> /var/log/docker_space_management.log
df -h >> /var/log/docker_space_management.log

# Log completion time
echo "Docker Space Management Process Completed at $(date)" >> /var/log/docker_space_management.log

# Send log file via email (optional)
# Replace with your email sending mechanism or leave this commented if not needed.
# mail -s "Docker Space Management Log" your-email@example.com < /var/log/docker_space_management.log
