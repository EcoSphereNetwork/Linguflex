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
    python3.12-dev \
    python3.12-distutils \
    python3-pip \
    python3-dev \
    python3-setuptools \
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
    cmake \
    python3-wheel

# Create and activate virtual environment
echo -e "${YELLOW}Creating Python virtual environment...${NC}"
python3.12 -m venv venv
source venv/bin/activate

# Set up Python environment
echo -e "${YELLOW}Setting up Python environment...${NC}"
pip install --upgrade pip setuptools wheel

# Install core build dependencies
echo -e "${YELLOW}Installing core build dependencies...${NC}"
pip install --no-cache-dir \
    setuptools \
    wheel \
    Cython \
    numpy==1.23.5

# Install the rest of the requirements with error handling
echo -e "${YELLOW}Installing Python dependencies...${NC}"
if ! pip install -r requirements_linux.txt; then
    echo -e "${RED}First attempt to install requirements failed. Trying alternative approach...${NC}"
    # Try installing requirements one by one
    while IFS= read -r requirement || [[ -n "$requirement" ]]; do
        # Skip comments and empty lines
        [[ $requirement =~ ^[[:space:]]*# ]] && continue
        [[ -z "$requirement" ]] && continue
        
        echo -e "${YELLOW}Installing $requirement...${NC}"
        if ! pip install --no-cache-dir "$requirement"; then
            echo -e "${RED}Failed to install $requirement${NC}"
            # Check if it's a critical package
            case "$requirement" in
                "numpy"*|"PyQt6"*|"RealtimeSTT"*|"RealtimeTTS"*|"setuptools"*|"wheel"*)
                    echo -e "${RED}Critical package $requirement failed to install. Aborting.${NC}"
                    exit 1
                    ;;
            esac
        fi
    done < requirements_linux.txt
fi

# Verify critical packages are installed
echo -e "${YELLOW}Verifying critical packages...${NC}"
for package in numpy PyQt6 RealtimeSTT RealtimeTTS; do
    if ! pip show $package > /dev/null 2>&1; then
        echo -e "${RED}Critical package $package is not installed. Installation failed.${NC}"
        exit 1
    fi
done

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