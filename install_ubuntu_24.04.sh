#!/bin/bash

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}Starting Linguflex installation for Ubuntu 24.04...${NC}"

# Check if running on Ubuntu 24.04
if ! grep -q "Ubuntu 24.04" /etc/os-release; then
    echo -e "${RED}This script is specifically for Ubuntu 24.04. Please use the appropriate installation script for your OS.${NC}"
    exit 1
fi

# Check if running with sudo
if [ "$EUID" -ne 0 ]; then 
    echo -e "${RED}Please run this script with sudo${NC}"
    exit 1
fi

# Create log directory
mkdir -p logs

echo -e "${YELLOW}Installing system dependencies...${NC}"
apt-get update
apt-get install -y \
    python3.12 \
    python3.12-venv \
    python3-pip \
    python3-dev \
    ffmpeg \
    portaudio19-dev \
    python3-pyqt6 \
    libespeak-ng1 \
    vlc \
    libsndfile1 \
    libasound2-dev \
    pulseaudio \
    git \
    build-essential \
    pkg-config \
    cmake

# Create and activate virtual environment
echo -e "${YELLOW}Creating Python virtual environment...${NC}"
python3.12 -m venv venv
source venv/bin/activate

# Upgrade pip
echo -e "${YELLOW}Upgrading pip...${NC}"
python3 -m pip install --upgrade pip

# Install Python dependencies
echo -e "${YELLOW}Installing Python dependencies...${NC}"
pip install -r requirements_linux.txt

# Apply Linux compatibility patch
echo -e "${YELLOW}Applying Linux compatibility patch...${NC}"
patch -p1 < linux_compatibility.patch

# Download models
echo -e "${YELLOW}Downloading required models...${NC}"
python3 download_models.py

# Set up proper permissions
echo -e "${YELLOW}Setting up permissions...${NC}"
chown -R $SUDO_USER:$SUDO_USER .
chmod +x start_linux.sh

# Create desktop entry
echo -e "${YELLOW}Creating desktop entry...${NC}"
cat > /usr/share/applications/linguflex.desktop << EOL
[Desktop Entry]
Name=Linguflex
Comment=AI Assistant
Exec=$(pwd)/start_linux.sh
Icon=$(pwd)/static/favicon.ico
Terminal=false
Type=Application
Categories=Utility;
EOL

echo -e "${GREEN}Installation complete!${NC}"
echo -e "${YELLOW}You can start Linguflex by:${NC}"
echo "1. Running ./start_linux.sh from the terminal"
echo "2. Using the Linguflex icon in your applications menu"
echo -e "${YELLOW}Note: The first run might take longer as it initializes the models.${NC}"

# Deactivate virtual environment
deactivate