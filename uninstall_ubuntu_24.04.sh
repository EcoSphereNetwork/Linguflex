#!/bin/bash

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

echo -e "${YELLOW}Starting Linguflex uninstallation...${NC}"

# Function to safely remove files/directories
safe_remove() {
    local path="$1"
    if [ -e "$path" ]; then
        echo -e "${YELLOW}Removing $path${NC}"
        rm -rf "$path"
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}Successfully removed $path${NC}"
        else
            echo -e "${RED}Failed to remove $path${NC}"
        fi
    else
        echo -e "${YELLOW}$path not found, skipping${NC}"
    fi
}

# Function to stop and disable service
cleanup_service() {
    local service="linguflex@$SUDO_USER"
    echo -e "${YELLOW}Stopping and disabling $service service...${NC}"
    
    if systemctl is-active --quiet "$service"; then
        systemctl stop "$service"
        echo -e "${GREEN}Service stopped${NC}"
    fi
    
    if systemctl is-enabled --quiet "$service" 2>/dev/null; then
        systemctl disable "$service"
        echo -e "${GREEN}Service disabled${NC}"
    fi
}

# Backup configuration if requested
echo -e "${YELLOW}Would you like to backup your configuration? [y/N]${NC}"
read -r backup_choice
if [[ "$backup_choice" =~ ^[Yy]$ ]]; then
    backup_dir="linguflex_backup_$(date +%Y%m%d_%H%M%S)"
    echo -e "${YELLOW}Creating backup in ~/$backup_dir${NC}"
    mkdir -p ~/"$backup_dir"
    
    # Backup configuration files
    if [ -d "/opt/linguflex" ]; then
        cp -r /opt/linguflex/settings.yaml ~/"$backup_dir"/ 2>/dev/null
    fi
    if [ -d "$HOME/.config/linguflex" ]; then
        cp -r "$HOME/.config/linguflex" ~/"$backup_dir"/ 2>/dev/null
    fi
    
    # Backup logs
    if [ -d "/var/log/linguflex" ]; then
        cp -r /var/log/linguflex ~/"$backup_dir"/ 2>/dev/null
    fi
    
    echo -e "${GREEN}Backup created in ~/$backup_dir${NC}"
fi

# Stop and disable service
cleanup_service

# Remove files and directories
echo -e "${YELLOW}Removing Linguflex files...${NC}"
safe_remove "/opt/linguflex"
safe_remove "/var/log/linguflex"
safe_remove "/etc/systemd/system/linguflex@.service"
safe_remove "/etc/pulse/client.conf.d/linguflex.conf"
safe_remove "/etc/logrotate.d/linguflex"
safe_remove "/usr/share/applications/linguflex.desktop"

# Remove virtual environment if it exists in current directory
if [ -d "venv" ]; then
    safe_remove "venv"
fi

# Clean up system
echo -e "${YELLOW}Cleaning up system...${NC}"
systemctl daemon-reload
echo -e "${GREEN}Systemd configuration reloaded${NC}"

# Clean up pip cache
if [ -n "$SUDO_USER" ]; then
    sudo -u "$SUDO_USER" pip cache purge
    echo -e "${GREEN}Pip cache cleaned${NC}"
fi

# Optional: Remove system dependencies
echo -e "${YELLOW}Would you like to remove system dependencies? [y/N]${NC}"
read -r remove_deps
if [[ "$remove_deps" =~ ^[Yy]$ ]]; then
    apt remove --autoremove -y \
        python3-pyqt6 \
        libespeak-ng1 \
        portaudio19-dev \
        python3.12-dev \
        python3.12-distutils
    echo -e "${GREEN}System dependencies removed${NC}"
fi

echo -e "${GREEN}Uninstallation complete!${NC}"
if [[ "$backup_choice" =~ ^[Yy]$ ]]; then
    echo -e "${YELLOW}Your configuration has been backed up to ~/$backup_dir${NC}"
fi

echo -e "${YELLOW}Note: If you installed any additional dependencies manually, you may need to remove them separately.${NC}"