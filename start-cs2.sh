#!/bin/bash
# -----------------------------
# CS2 Docker Server Launcher
# -----------------------------

# Your Game Server Login Token
GSLT="F79619FBA2121A93025EB334952517F5"

# Create a folder for persistent data
mkdir -p ./cs2-data
chown 1000:1000 ./cs2-data

# Run the container
docker run -d \
  --name=cs2 \
  -e SRCDS_TOKEN="$GSLT" \
  -e CS2_SERVERNAME="Goobert's 8s Server" \
  -e CS2_PW="1009" \
  -e CS2_MAXPLAYERS="16" \
  -e CS2_STARTMAP="de_dust2" \
  -p 27015:27015/tcp \
  -p 27015:27015/udp \
  -p 27020:27020/udp \
  -v "$(pwd)/cs2-data":/home/steam/cs2-dedicated/ \
  --restart unless-stopped \
  joedwards32/cs2
