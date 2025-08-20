#!/bin/bash
# CS2 Dedicated Server Setup Script for Ubuntu using tmux
# Usage: sudo bash cs2-tmux-setup.sh

# --- CONFIGURATION ---
STEAM_USER="steam"
CS2_DIR="/home/$STEAM_USER/cs2-server"
GSLT="F79619FBA2121A93025EB334952517F5"   # Your Steam Game Server Login Token
SERVER_NAME="8s by goobert"
MAP="de_dust2"
MAX_PLAYERS=16
SERVER_PASSWORD="1009"
TMUX_SESSION="cs2-server"

# --- UPDATE SYSTEM AND INSTALL DEPENDENCIES ---
echo "[INFO] Updating system and installing dependencies..."
sudo apt update && sudo apt upgrade -y
sudo apt install -y lib32gcc-s1 lib32stdc++6 libc6-i386 curl wget tmux screen nano

# --- CREATE STEAM USER ---
if ! id -u $STEAM_USER >/dev/null 2>&1; then
    echo "[INFO] Creating steam user..."
    sudo adduser --system --no-create-home --shell /bin/bash $STEAM_USER
fi

# --- INSTALL STEAMCMD ---
echo "[INFO] Installing SteamCMD..."
sudo -u $STEAM_USER mkdir -p /home/$STEAM_USER/steamcmd
cd /home/$STEAM_USER/steamcmd || exit
sudo -u $STEAM_USER curl -sqL "https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz" | sudo -u $STEAM_USER tar zxvf -

# --- DOWNLOAD CS2 SERVER FILES ---
echo "[INFO] Downloading CS2 server files (may take a while)..."
sudo -u $STEAM_USER ./steamcmd.sh +login anonymous +force_install_dir $CS2_DIR +app_update 730 validate +quit

# --- CREATE SERVER CONFIG ---
echo "[INFO] Creating server.cfg..."
sudo -u $STEAM_USER mkdir -p $CS2_DIR/csgo/cfg
cat <<EOL | sudo -u $STEAM_USER tee $CS2_DIR/csgo/cfg/server.cfg
hostname "$SERVER_NAME"
sv_setsteamaccount "$GSLT"
sv_password "$SERVER_PASSWORD"
mapgroup "mg_active"
gamemode 1
EOL

# --- CREATE START SCRIPT ---
echo "[INFO] Creating start-server.sh..."
cat <<EOL | sudo -u $STEAM_USER tee $CS2_DIR/start-server.sh
#!/bin/bash
cd $CS2_DIR
./cs2 -game csgo -console -usercon +map $MAP +maxplayers $MAX_PLAYERS +sv_setsteamaccount "$GSLT"
EOL
sudo chmod +x $CS2_DIR/start-server.sh

# --- START SERVER IN TMUX ---
echo "[INFO] Starting CS2 server in tmux session '$TMUX_SESSION'..."
sudo -u $STEAM_USER tmux new-session -d -s $TMUX_SESSION "$CS2_DIR/start-server.sh"

# --- FIREWALL SETUP ---
echo "[INFO] Configuring firewall..."
sudo ufw allow 27015:27030/tcp
sudo ufw allow 27000:27015/udp
sudo ufw reload

echo "[DONE] CS2 server setup complete! Use 'sudo -u $STEAM_USER tmux attach -t $TMUX_SESSION' to view server console."
