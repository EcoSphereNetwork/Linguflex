#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}Running Linguflex Diagnostics...${NC}"

# Function to check command existence
check_command() {
    if command -v $1 &> /dev/null; then
        echo -e "${GREEN}✓ $1 found${NC}"
        return 0
    else
        echo -e "${RED}✗ $1 not found${NC}"
        return 1
    fi
}

# Function to check Python package
check_package() {
    if python3 -c "import $1" &> /dev/null; then
        echo -e "${GREEN}✓ $1 package found${NC}"
        return 0
    else
        echo -e "${RED}✗ $1 package not found${NC}"
        return 1
    fi
}

# Function to check file/directory
check_path() {
    if [ -e "$1" ]; then
        echo -e "${GREEN}✓ $1 exists${NC}"
        return 0
    else
        echo -e "${RED}✗ $1 not found${NC}"
        return 1
    fi
}

echo -e "\n${YELLOW}Checking System Commands...${NC}"
check_command "python3.12"
check_command "pip"
check_command "git"
check_command "pulseaudio"
check_command "pactl"
check_command "ffmpeg"

echo -e "\n${YELLOW}Checking Virtual Environment...${NC}"
if [ -d "venv" ]; then
    echo -e "${GREEN}✓ Virtual environment exists${NC}"
    source venv/bin/activate
    echo -e "${GREEN}✓ Python version: $(python3 --version)${NC}"
    echo -e "${GREEN}✓ Pip version: $(pip --version)${NC}"
else
    echo -e "${RED}✗ Virtual environment not found${NC}"
fi

echo -e "\n${YELLOW}Checking Critical Python Packages...${NC}"
check_package "numpy"
check_package "PyQt6"
check_package "torch"
check_package "transformers"
check_package "RealtimeSTT"
check_package "RealtimeTTS"

echo -e "\n${YELLOW}Checking File Structure...${NC}"
check_path "/opt/linguflex"
check_path "/var/log/linguflex"
check_path "/etc/systemd/system/linguflex@.service"
check_path "/usr/share/applications/linguflex.desktop"

echo -e "\n${YELLOW}Checking Audio Setup...${NC}"
if pulseaudio --check; then
    echo -e "${GREEN}✓ PulseAudio is running${NC}"
    echo -e "\nAudio Sinks:"
    pactl list short sinks
    echo -e "\nAudio Sources:"
    pactl list short sources
else
    echo -e "${RED}✗ PulseAudio is not running${NC}"
fi

echo -e "\n${YELLOW}Checking Display Setup...${NC}"
echo "Display Server: $XDG_SESSION_TYPE"
echo "DISPLAY: $DISPLAY"
echo "WAYLAND_DISPLAY: $WAYLAND_DISPLAY"
if [ -n "$DISPLAY" ]; then
    echo -e "${GREEN}✓ X11 display is set${NC}"
elif [ -n "$WAYLAND_DISPLAY" ]; then
    echo -e "${GREEN}✓ Wayland display is set${NC}"
else
    echo -e "${RED}✗ No display server detected${NC}"
fi

echo -e "\n${YELLOW}Checking Service Status...${NC}"
if systemctl is-active --quiet linguflex@$USER; then
    echo -e "${GREEN}✓ Service is running${NC}"
    systemctl status linguflex@$USER --no-pager
else
    echo -e "${RED}✗ Service is not running${NC}"
fi

echo -e "\n${YELLOW}Checking Log Files...${NC}"
if [ -f "/var/log/linguflex/linguflex.log" ]; then
    echo -e "${GREEN}✓ Log file exists${NC}"
    echo -e "\nLast 10 lines of linguflex.log:"
    tail -n 10 /var/log/linguflex/linguflex.log
else
    echo -e "${RED}✗ Log file not found${NC}"
fi

echo -e "\n${YELLOW}Checking GPU Support...${NC}"
if command -v nvidia-smi &> /dev/null; then
    echo -e "${GREEN}✓ NVIDIA GPU detected${NC}"
    nvidia-smi --query-gpu=name,driver_version,memory.total --format=csv,noheader
else
    echo -e "${YELLOW}ℹ No NVIDIA GPU detected${NC}"
fi

echo -e "\n${YELLOW}System Resources...${NC}"
echo "Memory Usage:"
free -h
echo -e "\nDisk Space:"
df -h /opt/linguflex /var/log/linguflex

echo -e "\n${YELLOW}Diagnostics Complete!${NC}"