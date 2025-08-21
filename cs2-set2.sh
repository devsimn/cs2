#!/bin/bash
# CS2 Dedicated Server Setup Script for Ubuntu
# Usage: sudo bash cs2-setup.sh

# --- CONFIGURATION ---
STEAM_USER="steam"
CS2_DIR="/home/$STEAM_USER/cs2-server"
GSLT="F79619FBA2121A93025EB334952517F5"   # Your Steam Game Server Login Token
SERVER_NAME="8s by goobert"
MAP="de_dust2"
MAX_PLAYERS=16
SERVER_PASSWORD="1009"

# --- UPDATE SYSTEM AND INSTALL DEPENDENCIES ---
echo "[INFO] Updating system and installing dependencies..."
sudo apt update && sudo apt upgrade -y
sudo apt install -y lib32gcc-s1 lib32stdc++6 libc6-i386 curl wget tmux screen nano ufw

# --- CREATE STEAM USER AND HOME DIRECTORY ---
if ! id -u $STEAM_USER >/dev/null 2>&1; then
    echo "[INFO] Creating steam user with group..."
    sudo adduser --system --group --no-create-home --shell /bin/bash $STEAM_USER
fi

if [ ! -d /home/$STEAM_USER ]; then
    echo "[INFO] Creating /home/$STEAM_USER directory..."
    sudo mkdir -p /home/$STEAM_USER
    sudo chown $STEAM_USER:$STEAM_USER /home/$STEAM_USER
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
./srcds_run -game csgo -console -usercon +map $MAP +maxplayers $MAX_PLAYERS +sv_setsteamaccount "$GSLT"
EOL
sudo chmod +x $CS2_DIR/start-server.sh
sudo chmod +x $CS2_DIR/srcds_run 2>/dev/null || true  # ensure srcds_run is executable

# --- CREATE SYSTEMD SERVICE ---
echo "[INFO] Setting up systemd service..."
cat <<EOL | sudo tee /etc/systemd/system/cs2.service
[Unit]
Description=Counter-Strike 2 Dedicated Server
After=network.target

[Service]
User=$STEAM_USER
WorkingDirectory=$CS2_DIR
ExecStart=$CS2_DIR/start-server.sh
Restart=always

[Install]
WantedBy=multi-user.target
EOL

# --- ENABLE AND START SERVICE ---
sudo systemctl daemon-reload
sudo systemctl enable cs2
sudo systemctl start cs2

# --- FIREWALL SETUP ---
if sudo ufw status | grep -q "inactive"; then
    echo "[INFO] Enabling UFW firewall..."
    sudo ufw enable
fi
echo "[INFO] Configuring firewall rules..."
sudo ufw allow 27015:27030/tcp
sudo ufw allow 27000:27015/udp
sudo ufw reload

echo "[DONE] CS2 server setup complete! Use 'sudo systemctl status cs2' to check the server."
