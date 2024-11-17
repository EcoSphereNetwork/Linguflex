#!/bin/bash

echo "Installing Linguflex for Ubuntu 24.04..."

# Create virtual environment if it doesn't exist
if [ ! -d "venv" ]; then
    echo "Creating virtual environment..."
    python3 -m venv venv
fi

# Activate virtual environment
source venv/bin/activate

# Install system dependencies
echo "Installing system dependencies..."
sudo apt-get update
sudo apt-get install -y \
    python3-dev \
    python3-pip \
    ffmpeg \
    portaudio19-dev \
    python3-pyqt6 \
    libespeak-ng1 \
    vlc \
    libsndfile1 \
    libasound2-dev

# Upgrade pip
python3 -m pip install --upgrade pip

# Install Python dependencies
echo "Installing Python dependencies..."
pip install -r requirements_linux.txt

# Download models
echo "Downloading required models..."
python3 download_models.py

# Create log directory
mkdir -p logs

echo "Installation complete! You can start Linguflex by running: ./start_linux.sh"

# Make the start script executable
chmod +x start_linux.sh