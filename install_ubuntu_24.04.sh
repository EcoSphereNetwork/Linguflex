#!/bin/bash

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to check system requirements
check_system_requirements() {
    echo -e "${YELLOW}Checking system requirements...${NC}"
    
    # Check Ubuntu version
    if ! grep -q "Ubuntu 24.04" /etc/os-release; then
        echo -e "${RED}Error: This script requires Ubuntu 24.04${NC}"
        return 1
    fi

    # Check available disk space (need at least 10GB)
    available_space=$(df -BG . | awk 'NR==2 {print $4}' | sed 's/G//')
    if [ "$available_space" -lt 10 ]; then
        echo -e "${RED}Error: Not enough disk space. Need at least 10GB, have ${available_space}GB${NC}"
        return 1
    fi

    # Check available RAM (need at least 4GB)
    total_ram=$(free -g | awk '/^Mem:/{print $2}')
    if [ "$total_ram" -lt 4 ]; then
        echo -e "${RED}Error: Not enough RAM. Need at least 4GB, have ${total_ram}GB${NC}"
        return 1
    fi

    # Check if required commands are available
    for cmd in python3.12 git patch curl wget; do
        if ! command -v $cmd &> /dev/null; then
            echo -e "${RED}Error: Required command '$cmd' not found${NC}"
            return 1
        fi
    done

    # Check Python version
    python_version=$(python3.12 -c 'import sys; print(".".join(map(str, sys.version_info[:2])))')
    if [[ "$python_version" != "3.12" ]]; then
        echo -e "${RED}Error: Python 3.12 required, found version $python_version${NC}"
        return 1
    fi

    # Check internet connectivity
    if ! ping -c 1 8.8.8.8 &> /dev/null; then
        echo -e "${RED}Error: No internet connection${NC}"
        return 1
    fi

    echo -e "${GREEN}System requirements check passed${NC}"
    return 0
}

# Function to suggest fixes for failed checks
suggest_fixes() {
    local check_type="$1"
    echo -e "${YELLOW}Suggested fixes for $check_type issues:${NC}"
    
    case "$check_type" in
        "system")
            echo "1. Ensure you have Python 3.12 installed:"
            echo "   sudo add-apt-repository ppa:deadsnakes/ppa"
            echo "   sudo apt update"
            echo "   sudo apt install python3.12 python3.12-dev python3.12-distutils"
            echo "2. Free up disk space if needed:"
            echo "   sudo apt clean"
            echo "   sudo apt autoremove"
            echo "3. Ensure all required tools are installed:"
            echo "   sudo apt install git patch curl wget"
            ;;
        "audio")
            echo "1. Install PulseAudio if not present:"
            echo "   sudo apt install pulseaudio"
            echo "2. Restart PulseAudio:"
            echo "   pulseaudio -k"
            echo "   pulseaudio --start"
            echo "3. Check audio devices:"
            echo "   pactl list short sinks"
            echo "   pactl list short sources"
            echo "4. Ensure your user is in the audio group:"
            echo "   sudo usermod -a -G audio \$USER"
            ;;
        "display")
            echo "1. Install X11/Wayland dependencies:"
            echo "   sudo apt install python3-pyqt6 python3-pyqt6.qtwebengine"
            echo "2. Check display server:"
            echo "   echo \$DISPLAY"
            echo "   echo \$WAYLAND_DISPLAY"
            echo "3. If running via SSH, ensure X11 forwarding is enabled:"
            echo "   ssh -X user@host"
            ;;
    esac
}

# Function to check audio setup
check_audio_setup() {
    echo -e "${YELLOW}Checking audio setup...${NC}"
    
    # Check if PulseAudio is installed and running
    if ! command -v pulseaudio &> /dev/null; then
        echo -e "${RED}Error: PulseAudio is not installed${NC}"
        return 1
    fi
    
    if ! pulseaudio --check; then
        echo -e "${YELLOW}Warning: PulseAudio is not running. Attempting to start...${NC}"
        pulseaudio --start
        sleep 2
        if ! pulseaudio --check; then
            echo -e "${RED}Error: Failed to start PulseAudio${NC}"
            return 1
        fi
    fi

    # Check for audio devices
    if ! pacmd list-sinks &> /dev/null; then
        echo -e "${RED}Error: No audio output devices found${NC}"
        return 1
    fi

    if ! pacmd list-sources &> /dev/null; then
        echo -e "${RED}Error: No audio input devices found${NC}"
        return 1
    fi

    return 0
}

# Function to check display setup
check_display_setup() {
    echo -e "${YELLOW}Checking display setup...${NC}"
    
    # Check if X11 or Wayland is running
    if [ -z "$DISPLAY" ] && [ -z "$WAYLAND_DISPLAY" ]; then
        echo -e "${RED}Error: No display server detected. X11 or Wayland is required${NC}"
        return 1
    fi

    # Check if Qt dependencies are available
    if ! dpkg -l | grep -q "python3-pyqt6"; then
        echo -e "${RED}Error: PyQt6 system dependencies not found${NC}"
        return 1
    fi

    return 0
}

echo -e "${GREEN}Starting Linguflex installation for Ubuntu 24.04...${NC}"

# Run system requirements check
if ! check_system_requirements; then
    echo -e "${RED}System requirements check failed.${NC}"
    suggest_fixes "system"
    exit 1
fi

# Run audio setup check
if ! check_audio_setup; then
    echo -e "${RED}Audio setup check failed.${NC}"
    suggest_fixes "audio"
    exit 1
fi

# Run display setup check
if ! check_display_setup; then
    echo -e "${RED}Display setup check failed.${NC}"
    suggest_fixes "display"
    exit 1
fi

echo -e "${GREEN}All pre-installation checks passed successfully!${NC}"

# Check if running with sudo
if [ "$EUID" -ne 0 ]; then 
    echo -e "${RED}Please run this script with sudo${NC}"
    exit 1
fi

# Create log directory
mkdir -p logs

echo -e "${YELLOW}Installing system dependencies...${NC}"

# Add deadsnakes PPA if Python 3.12 is not available
if ! command -v python3.12 &> /dev/null; then
    echo -e "${YELLOW}Python 3.12 not found. Adding deadsnakes PPA...${NC}"
    apt-get install -y software-properties-common
    add-apt-repository -y ppa:deadsnakes/ppa
    apt-get update
fi

# Install system dependencies
apt-get install -y \
    python3.12 \
    python3.12-venv \
    python3.12-dev \
    python3-pip \
    python3-setuptools \
    python3-distutils-extra \
    python3-wheel \
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

# Install Python 3.12 and required packages
echo -e "${YELLOW}Installing Python 3.12 and dependencies...${NC}"
apt-get install -y \
    python3.12-full \
    python3.12-venv \
    python3-pip \
    python3-setuptools \
    python3-wheel \
    python3-distutils-extra

# Verify Python installation
if ! python3.12 --version; then
    echo -e "${RED}Python 3.12 installation failed${NC}"
    exit 1
fi

# Create and activate virtual environment
echo -e "${YELLOW}Creating Python virtual environment...${NC}"
if [ -d "venv" ]; then
    echo -e "${YELLOW}Existing virtual environment found. Removing...${NC}"
    rm -rf venv
fi

# Create virtual environment with system packages to avoid PEP 668 issues
if ! python3.12 -m venv venv --system-site-packages; then
    echo -e "${RED}Failed to create virtual environment${NC}"
    exit 1
fi

# Activate virtual environment
if ! source venv/bin/activate; then
    echo -e "${RED}Failed to activate virtual environment${NC}"
    exit 1
fi

# Verify virtual environment
if [[ "$(which python)" != *"/venv/bin/python" ]]; then
    echo -e "${RED}Virtual environment activation failed${NC}"
    exit 1
fi

echo -e "${GREEN}Python version in virtual environment:${NC}"
python --version

# Set up Python environment with system packages
echo -e "${YELLOW}Setting up Python environment...${NC}"
python -m pip install --upgrade pip

# Install core build dependencies
echo -e "${YELLOW}Installing core build dependencies...${NC}"
python -m pip install --no-cache-dir \
    setuptools \
    wheel \
    distutils-extra \
    Cython \
    numpy==1.23.5

# Verify pip installation
if ! python -m pip --version; then
    echo -e "${RED}Pip installation failed${NC}"
    exit 1
fi

echo -e "${GREEN}Pip version in virtual environment:${NC}"
python -m pip --version

# Install the rest of the requirements with error handling
echo -e "${YELLOW}Installing Python dependencies...${NC}"

# First try: Install all requirements at once
if ! python -m pip install -r requirements_linux.txt; then
    echo -e "${YELLOW}Bulk installation failed. Trying sequential installation...${NC}"
    
    # Second try: Install requirements one by one
    while IFS= read -r requirement || [[ -n "$requirement" ]]; do
        # Skip comments and empty lines
        [[ $requirement =~ ^[[:space:]]*# ]] && continue
        [[ -z "$requirement" ]] && continue
        
        echo -e "${YELLOW}Installing $requirement...${NC}"
        if ! python -m pip install --no-cache-dir "$requirement"; then
            # Third try: If package fails, try with --no-deps
            echo -e "${YELLOW}Retrying $requirement with --no-deps...${NC}"
            if ! python -m pip install --no-cache-dir --no-deps "$requirement"; then
                echo -e "${RED}Failed to install $requirement${NC}"
                
                # Check if it's a critical package
                case "$requirement" in
                    "numpy"*|"PyQt6"*|"RealtimeSTT"*|"RealtimeTTS"*|"torch"*|"transformers"*)
                        echo -e "${RED}Critical package $requirement failed to install. Aborting.${NC}"
                        echo -e "${YELLOW}Try installing it manually with:${NC}"
                        echo "python -m pip install $requirement"
                        exit 1
                        ;;
                esac
            fi
        fi
    done < requirements_linux.txt
    
    # Final try: Install dependencies that might have been skipped
    echo -e "${YELLOW}Installing missing dependencies...${NC}"
    if ! python -m pip install --no-cache-dir -r requirements_linux.txt; then
        echo -e "${YELLOW}Some dependencies might be missing, but core packages are installed${NC}"
    fi
fi

# Verify critical packages
echo -e "${YELLOW}Verifying critical packages...${NC}"
critical_packages=("numpy" "PyQt6" "RealtimeSTT" "RealtimeTTS" "torch" "transformers")
for package in "${critical_packages[@]}"; do
    if ! python -c "import $package" &>/dev/null; then
        echo -e "${RED}Critical package $package is not properly installed${NC}"
        echo -e "${YELLOW}Try installing it manually with:${NC}"
        echo "python -m pip install $package"
        exit 1
    else
        echo -e "${GREEN}✓ $package${NC}"
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

# Function to verify installation
verify_installation() {
    echo -e "${YELLOW}Verifying installation...${NC}"
    local errors=0

    # Check if virtual environment is active and working
    if ! python3 -c "import sys; sys.exit(0 if sys.prefix != sys.base_prefix else 1)"; then
        echo -e "${RED}Error: Virtual environment is not active${NC}"
        errors=$((errors + 1))
    fi

    # Check critical Python packages
    local packages=("numpy" "PyQt6" "RealtimeSTT" "RealtimeTTS" "torch" "transformers")
    for package in "${packages[@]}"; do
        if ! python3 -c "import $package" &> /dev/null; then
            echo -e "${RED}Error: Package '$package' is not properly installed${NC}"
            errors=$((errors + 1))
        fi
    done

    # Check if models were downloaded
    if [ ! -d "models" ]; then
        echo -e "${RED}Error: Models directory not found${NC}"
        errors=$((errors + 1))
    fi

    # Check desktop entry
    if [ ! -f "/usr/share/applications/linguflex.desktop" ]; then
        echo -e "${RED}Error: Desktop entry not created${NC}"
        errors=$((errors + 1))
    fi

    # Check service file
    if [ ! -f "/etc/systemd/system/linguflex@.service" ]; then
        echo -e "${RED}Error: Systemd service file not installed${NC}"
        errors=$((errors + 1))
    fi

    # Check file permissions
    if [ ! -x "start_linux.sh" ]; then
        echo -e "${RED}Error: start_linux.sh is not executable${NC}"
        errors=$((errors + 1))
    fi

    if [ $errors -eq 0 ]; then
        echo -e "${GREEN}Installation verification passed successfully!${NC}"
        return 0
    else
        echo -e "${RED}Installation verification failed with $errors errors${NC}"
        return 1
    fi
}

# Run verification
if ! verify_installation; then
    echo -e "${RED}Installation completed with errors. Please check the messages above.${NC}"
    echo -e "${YELLOW}You may need to run the following commands to fix issues:${NC}"
    echo "1. sudo chmod +x start_linux.sh"
    echo "2. sudo systemctl daemon-reload"
    echo "3. Check logs in /var/log/linguflex/"
else
    echo -e "${GREEN}Installation completed successfully!${NC}"
    echo -e "${YELLOW}You can start Linguflex by:${NC}"
    echo "1. Running ./start_linux.sh from the terminal"
    echo "2. Using the Linguflex icon in your applications menu"
    echo "3. Starting as a service: sudo systemctl start linguflex@\$USER"
    echo -e "\n${YELLOW}To enable Linguflex to start on boot:${NC}"
    echo "sudo systemctl enable linguflex@\$USER"
    echo -e "\n${YELLOW}To view logs:${NC}"
    echo "tail -f /var/log/linguflex/linguflex.log"
    echo -e "\n${YELLOW}Note: The first run might take longer as it initializes the models.${NC}"
fi

# Deactivate virtual environment
deactivate