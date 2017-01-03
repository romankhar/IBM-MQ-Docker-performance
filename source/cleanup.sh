#!/bin/bash

# This script cleans up dockercontainers and images to free up disk space.
# After running this, all local images will have to be rebuilt

docker rm `docker ps --no-trunc -a -q`
docker images | grep '' | awk '{print $3}' | xargs docker rmi
exit 0