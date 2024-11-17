#!/bin/bash

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if running with sudo
if [ "$EUID" -ne 0 ]; then 
    echo -e "${RED}Please run this script with sudo${NC}"
    exit 1
fi

echo -e "${GREEN}Configuring Linguflex service for Ubuntu 24.04...${NC}"

# Create necessary directories
echo -e "${YELLOW}Creating system directories...${NC}"
mkdir -p /opt/linguflex
mkdir -p /var/log/linguflex

# Copy files to system location
echo -e "${YELLOW}Copying files to system location...${NC}"
cp -r . /opt/linguflex/

# Set up logging
echo -e "${YELLOW}Setting up logging...${NC}"
touch /var/log/linguflex/linguflex.log
touch /var/log/linguflex/error.log

# Set proper ownership and permissions
echo -e "${YELLOW}Setting up permissions...${NC}"
chown -R $SUDO_USER:$SUDO_USER /opt/linguflex
chown -R $SUDO_USER:$SUDO_USER /var/log/linguflex
chmod 755 /opt/linguflex
chmod 755 /var/log/linguflex
chmod 644 /var/log/linguflex/*.log

# Install systemd service
echo -e "${YELLOW}Installing systemd service...${NC}"
cp /opt/linguflex/linguflex.service /etc/systemd/system/linguflex@.service
systemctl daemon-reload

# Create audio group if it doesn't exist and add user to it
echo -e "${YELLOW}Setting up audio permissions...${NC}"
getent group audio || groupadd audio
usermod -a -G audio $SUDO_USER

# Set up PulseAudio for the service user
echo -e "${YELLOW}Configuring PulseAudio...${NC}"
cat > /etc/pulse/client.conf.d/linguflex.conf << EOL
# Allow PulseAudio to be accessed by the Linguflex service
autospawn = yes
daemon-binary = /usr/bin/pulseaudio
enable-shm = yes
EOL

# Create convenience scripts
echo -e "${YELLOW}Creating convenience scripts...${NC}"
cat > /opt/linguflex/start_service.sh << EOL
#!/bin/bash
sudo systemctl start linguflex@\$USER
EOL

cat > /opt/linguflex/stop_service.sh << EOL
#!/bin/bash
sudo systemctl stop linguflex@\$USER
EOL

cat > /opt/linguflex/restart_service.sh << EOL
#!/bin/bash
sudo systemctl restart linguflex@\$USER
EOL

chmod +x /opt/linguflex/*.sh

# Set up log rotation
echo -e "${YELLOW}Setting up log rotation...${NC}"
cat > /etc/logrotate.d/linguflex << EOL
/var/log/linguflex/*.log {
    daily
    rotate 7
    compress
    delaycompress
    missingok
    notifempty
    create 644 $SUDO_USER $SUDO_USER
}
EOL

echo -e "${GREEN}Configuration complete!${NC}"
echo -e "${YELLOW}You can now:${NC}"
echo "1. Start the service: sudo systemctl start linguflex@\$USER"
echo "2. Enable service at boot: sudo systemctl enable linguflex@\$USER"
echo "3. Check service status: sudo systemctl status linguflex@\$USER"
echo "4. View logs: tail -f /var/log/linguflex/linguflex.log"
echo -e "${YELLOW}Note: The service will run as your user account for proper desktop integration${NC}"