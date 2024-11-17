#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== Linguflex System Information Report ===${NC}"
date

echo -e "\n${YELLOW}=== System Information ===${NC}"
echo -e "${GREEN}Operating System:${NC}"
lsb_release -a 2>/dev/null || cat /etc/os-release

echo -e "\n${GREEN}Kernel Information:${NC}"
uname -a

echo -e "\n${GREEN}CPU Information:${NC}"
lscpu | grep -E "Model name|CPU\(s\)|Thread|Core|Socket|MHz"

echo -e "\n${GREEN}Memory Information:${NC}"
free -h

echo -e "\n${GREEN}Disk Space:${NC}"
df -h

echo -e "\n${YELLOW}=== Python Environment ===${NC}"
echo -e "${GREEN}Python Version:${NC}"
python3 --version 2>/dev/null || echo "Python3 not found"
python3.12 --version 2>/dev/null || echo "Python3.12 not found"

echo -e "\n${GREEN}Pip Version:${NC}"
pip --version 2>/dev/null || echo "Pip not found"

if [ -d "venv" ]; then
    echo -e "\n${GREEN}Virtual Environment Packages:${NC}"
    source venv/bin/activate
    pip list
    deactivate
else
    echo -e "\n${RED}Virtual environment not found${NC}"
fi

echo -e "\n${YELLOW}=== Audio Configuration ===${NC}"
echo -e "${GREEN}PulseAudio Version:${NC}"
pulseaudio --version 2>/dev/null || echo "PulseAudio not found"

echo -e "\n${GREEN}Audio Devices:${NC}"
if command -v pactl &> /dev/null; then
    echo "=== Audio Sinks ==="
    pactl list short sinks
    echo "=== Audio Sources ==="
    pactl list short sources
else
    echo "pactl not found"
fi

echo -e "\n${YELLOW}=== Display Configuration ===${NC}"
echo -e "${GREEN}Display Server:${NC} $XDG_SESSION_TYPE"
echo -e "${GREEN}DISPLAY:${NC} $DISPLAY"
echo -e "${GREEN}WAYLAND_DISPLAY:${NC} $WAYLAND_DISPLAY"

echo -e "\n${GREEN}Qt/PyQt Information:${NC}"
dpkg -l | grep -E "pyqt|qt6" || echo "No Qt packages found"

echo -e "\n${YELLOW}=== GPU Information ===${NC}"
if command -v nvidia-smi &> /dev/null; then
    echo -e "${GREEN}NVIDIA GPU:${NC}"
    nvidia-smi --query-gpu=gpu_name,driver_version,memory.total,memory.used --format=csv,noheader
else
    echo -e "${GREEN}Integrated/Other GPU:${NC}"
    lspci | grep -i vga
fi

echo -e "\n${YELLOW}=== Service Status ===${NC}"
if systemctl is-active --quiet linguflex@$USER; then
    echo -e "${GREEN}Service Status:${NC}"
    systemctl status linguflex@$USER --no-pager
else
    echo -e "${RED}Linguflex service is not running${NC}"
fi

echo -e "\n${YELLOW}=== Installation Paths ===${NC}"
for path in "/opt/linguflex" "/var/log/linguflex" "/etc/systemd/system/linguflex@.service" "/usr/share/applications/linguflex.desktop" "~/.config/linguflex"; do
    if [ -e "$path" ]; then
        echo -e "${GREEN}✓${NC} $path"
        ls -l "$path" 2>/dev/null
    else
        echo -e "${RED}✗${NC} $path (not found)"
    fi
done

echo -e "\n${YELLOW}=== Network Configuration ===${NC}"
echo -e "${GREEN}Network Interfaces:${NC}"
ip addr show

echo -e "\n${GREEN}Internet Connectivity:${NC}"
ping -c 1 8.8.8.8 &>/dev/null && echo "Internet: Connected" || echo "Internet: Not Connected"

echo -e "\n${YELLOW}=== System Logs ===${NC}"
echo -e "${GREEN}Last 5 lines of linguflex.log:${NC}"
tail -n 5 /var/log/linguflex/linguflex.log 2>/dev/null || echo "Log file not found"

echo -e "\n${GREEN}Recent System Messages:${NC}"
journalctl -u linguflex@$USER --no-pager -n 5 2>/dev/null || echo "No recent messages found"

echo -e "\n${BLUE}=== Report Complete ===${NC}"
echo "Generated on: $(date)"
echo "Hostname: $(hostname)"
echo "User: $USER"