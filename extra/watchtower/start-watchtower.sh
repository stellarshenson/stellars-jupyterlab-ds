#! /bin/sh
echo "starting watchtower to attempt refresh containers every 1h"
docker run -d \
  --name watchtower \
  --restart unless-stopped \
  -v /var/run/docker.sock:/var/run/docker.sock \
  containrrr/watchtower \
  --interval 3600

