# Installing Linguflex on Ubuntu 24.04 LTS

This guide provides detailed instructions for installing and running Linguflex on Ubuntu 24.04 LTS.

## System Requirements

### Hardware Requirements
- At least 4GB RAM (8GB recommended)
- 10GB free disk space
- Working audio input/output devices
- Display with X11 or Wayland support

### Software Requirements
- Ubuntu 24.04 LTS
- Python 3.12
- PulseAudio
- X11 or Wayland display server
- Internet connection

### Optional Requirements
- NVIDIA GPU for improved performance
- Webcam for video features
- SSH with X11 forwarding for remote access

## Pre-Installation Steps

1. Update your system:
   ```bash
   sudo apt update && sudo apt upgrade -y
   ```

2. Install Python 3.12 (the installation script will do this automatically, but you can also do it manually):
   ```bash
   # Install prerequisites
   sudo apt install software-properties-common

   # Add deadsnakes PPA
   sudo add-apt-repository ppa:deadsnakes/ppa
   sudo apt update

   # Install Python 3.12 and development tools
   sudo apt install python3.12 python3.12-dev python3.12-venv

   # Install pip and setuptools for Python 3.12
   curl -sS https://bootstrap.pypa.io/get-pip.py | sudo python3.12
   sudo python3.12 -m pip install setuptools wheel distutils-extra

   # Verify installation
   python3.12 --version
   python3.12 -m pip --version
   ```

3. Install required system packages:
   ```bash
   sudo apt install git python3-pip ffmpeg portaudio19-dev python3-pyqt6 libespeak-ng1 vlc libsndfile1 libasound2-dev pulseaudio
   ```

## Installation Methods

### Method 1: Desktop Installation (Recommended)

1. Clone the repository:
   ```bash
   git clone https://github.com/EcoSphereNetwork/Linguflex.git
   cd Linguflex
   ```

2. Run the installation script:
   ```bash
   sudo chmod +x install_ubuntu_24.04.sh
   sudo ./install_ubuntu_24.04.sh
   ```
   The script will:
   - Verify system requirements
   - Check audio and display setup
   - Install all dependencies
   - Set up virtual environment
   - Download required models
   - Create desktop entry
   - Configure permissions

3. Start Linguflex:
   - Option 1: Run `./start_linux.sh` from terminal
   - Option 2: Launch from applications menu
   - Option 3: Use systemd service (see below)

### Method 2: Service Installation

After completing Method 1, you can run Linguflex as a system service:

1. Start the service:
   ```bash
   sudo systemctl start linguflex@$USER
   ```

2. Enable automatic start on boot:
   ```bash
   sudo systemctl enable linguflex@$USER
   ```

3. Check service status:
   ```bash
   sudo systemctl status linguflex@$USER
   ```

4. View logs:
   ```bash
   tail -f /var/log/linguflex/linguflex.log
   ```

### Method 3: Development Installation

For developers who want to contribute:

1. Clone with git history:
   ```bash
   git clone --depth=1 https://github.com/linguflex/Linguflex.git
   cd Linguflex
   ```

2. Create development environment:
   ```bash
   python3.12 -m venv venv
   source venv/bin/activate
   pip install -r requirements_linux.txt
   ```

3. Run in development mode:
   ```bash
   PYTHONPATH=$PWD python3 -m lingu.core.run
   ```

## Troubleshooting

### Installation Issues

1. Python 3.12 installation errors:
   ```bash
   # Clean up any failed installations
   sudo apt remove python3.12 python3.12-dev python3.12-venv
   sudo apt autoremove
   
   # Clear package lists and update
   sudo rm -rf /var/lib/apt/lists/*
   sudo apt update
   
   # Reinstall Python 3.12
   sudo apt install software-properties-common
   sudo add-apt-repository ppa:deadsnakes/ppa
   sudo apt update
   sudo apt install python3.12 python3.12-dev python3.12-venv
   
   # Install pip and essential packages
   curl -sS https://bootstrap.pypa.io/get-pip.py | sudo python3.12
   sudo python3.12 -m pip install --upgrade pip setuptools wheel distutils-extra
   ```

2. Virtual environment issues:
   ```bash
   # Remove existing virtual environment
   rm -rf venv
   
   # Create new virtual environment
   python3.12 -m venv venv
   
   # Activate and verify
   source venv/bin/activate
   which python  # Should show path to venv
   python --version  # Should show Python 3.12
   ```

3. Permission errors:
   ```bash
   # Fix ownership and permissions for local Python packages
   sudo chown -R $USER:$USER ~/.local
   sudo chmod -R u+rw ~/.local
   
   # Fix virtual environment permissions
   sudo chown -R $USER:$USER venv
   chmod -R u+rw venv
   
   # Fix pip cache permissions
   sudo chown -R $USER:$USER ~/.cache/pip
   chmod -R u+rw ~/.cache/pip
   ```

4. Package installation failures:
   ```bash
   # Clear pip cache
   pip cache purge
   
   # Try installing with --no-cache-dir
   pip install --no-cache-dir -r requirements_linux.txt
   
   # If specific package fails, try installing its dependencies first
   pip install --no-cache-dir setuptools wheel
   pip install --no-cache-dir numpy==1.23.5
   pip install --no-cache-dir -r requirements_linux.txt
   ```

5. Build errors:
   ```bash
   # Install build essentials
   sudo apt install build-essential pkg-config cmake
   
   # Install Python development tools
   sudo apt install python3.12-dev
   
   # Clear previous build files
   find . -type d -name "build" -exec rm -rf {} +
   find . -type d -name "dist" -exec rm -rf {} +
   find . -type d -name "*.egg-info" -exec rm -rf {} +
   ```

6. SSL/TLS errors:
   ```bash
   # Update certificates
   sudo apt install ca-certificates
   sudo update-ca-certificates
   
   # If pip has SSL issues
   pip install --trusted-host pypi.org --trusted-host files.pythonhosted.org -r requirements_linux.txt
   ```

7. Memory errors during installation:
   ```bash
   # Clear system cache
   sudo sync && sudo echo 3 | sudo tee /proc/sys/vm/drop_caches
   
   # Install packages one by one with reduced parallelism
   while read requirement; do
       [[ $requirement =~ ^#.* ]] && continue
       [[ -z $requirement ]] && continue
       pip install --no-cache-dir --no-deps $requirement
   done < requirements_linux.txt
   ```

8. PulseAudio issues:
   ```bash
   # Fix PulseAudio running as root
   systemctl --user enable pulseaudio
   systemctl --user start pulseaudio
   
   # Reset PulseAudio configuration
   rm -rf ~/.config/pulse
   systemctl --user restart pulseaudio
   
   # Check audio devices
   pactl list short sinks
   pactl list short sources
   
   # Test audio output
   paplay /usr/share/sounds/freedesktop/stereo/audio-test-signal.oga
   
   # If PulseAudio fails to start
   pulseaudio -k
   pulseaudio --start --log-target=syslog
   
   # Debug PulseAudio
   LANG=C pulseaudio -vvvv
   ```

9. Model download issues:
   ```bash
   # Clear model cache
   rm -rf models/*
   
   # Download with progress
   python3 download_models.py --progress
   
   # If download fails, try with curl
   mkdir -p models
   cd models
   curl -C - -L "MODEL_URL" -o "model_file.bin"
   
   # Verify downloads
   sha256sum models/* | grep -f model_checksums.txt
   ```

10. Display server issues:
    ```bash
    # Check display server type
    echo $XDG_SESSION_TYPE
    
    # For X11
    xhost +local:  # Allow local connections
    export DISPLAY=:0
    
    # For Wayland
    export QT_QPA_PLATFORM=wayland
    export GDK_BACKEND=wayland
    
    # Test X11 forwarding
    xeyes  # Should show a pair of eyes following your cursor
    
    # Check Qt installation
    sudo apt install --reinstall python3-pyqt6 python3-pyqt6.qtwebengine
    
    # Debug display issues
    export QT_DEBUG_PLUGINS=1
    export QT_LOGGING_RULES="qt.qpa.*=true"
    ```

11. GPU acceleration issues:
    ```bash
    # Check NVIDIA drivers
    nvidia-smi
    
    # Install NVIDIA drivers if needed
    ubuntu-drivers devices
    sudo ubuntu-drivers autoinstall
    
    # Install CUDA support
    sudo apt install nvidia-cuda-toolkit
    
    # Verify PyTorch GPU support
    python3 -c "import torch; print('CUDA available:', torch.cuda.is_available())"
    ```

### Audio Issues

1. Basic audio troubleshooting:
   ```bash
   # Check PulseAudio status
   pulseaudio --check
   pactl info
   
   # List audio devices
   pactl list short sinks
   pactl list short sources
   
   # Restart PulseAudio
   pulseaudio -k
   pulseaudio --start
   ```

2. Permission issues:
   ```bash
   # Add user to audio group
   sudo usermod -a -G audio $USER
   sudo usermod -a -G pulse-access $USER
   
   # Fix PulseAudio permissions
   sudo chown -R $USER:$USER ~/.config/pulse
   ```

3. Device configuration:
   ```bash
   # Set default devices
   pactl set-default-sink <sink_name>
   pactl set-default-source <source_name>
   
   # Test audio
   paplay /usr/share/sounds/freedesktop/stereo/audio-test-signal.oga
   ```

### Display Issues

1. X11/Wayland setup:
   ```bash
   # Check display server
   echo $XDG_SESSION_TYPE
   
   # X11 permissions
   xhost +local:
   
   # Check environment
   echo $DISPLAY
   echo $WAYLAND_DISPLAY
   ```

2. Qt/PyQt6 issues:
   ```bash
   # Reinstall Qt dependencies
   sudo apt install --reinstall python3-pyqt6 python3-pyqt6.qtwebengine
   
   # Force X11 backend
   export QT_QPA_PLATFORM=xcb
   ```

3. Remote display:
   ```bash
   # Enable X11 forwarding
   ssh -X user@host
   
   # Test X11 forwarding
   xeyes
   ```

### Service Issues

1. Service management:
   ```bash
   # Check service status
   sudo systemctl status linguflex@$USER
   
   # View service configuration
   sudo systemctl cat linguflex@$USER
   
   # Reset service
   sudo systemctl reset-failed linguflex@$USER
   sudo systemctl restart linguflex@$USER
   ```

2. Log analysis:
   ```bash
   # View all logs
   journalctl -u linguflex@$USER
   
   # View real-time logs
   tail -f /var/log/linguflex/linguflex.log
   tail -f /var/log/linguflex/error.log
   ```

3. Permission fixes:
   ```bash
   # Fix service permissions
   sudo chown -R $USER:$USER /opt/linguflex
   sudo chmod 755 /opt/linguflex/start_linux.sh
   ```

### Common Problems

1. "No module named 'X'":
   - Ensure virtual environment is activated
   - Reinstall the missing package: `pip install X`
   - Check `PYTHONPATH`: `echo $PYTHONPATH`

2. "Failed to connect to PulseAudio":
   - Check PulseAudio status
   - Restart PulseAudio
   - Verify audio group membership

3. "QXcbConnection: Could not connect to display":
   - Check display server
   - Verify X11/Wayland is running
   - Check display permissions

## Uninstallation

### Method 1: Using uninstall script
```bash
sudo ./uninstall_ubuntu_24.04.sh
```

### Method 2: Manual uninstallation
```bash
# Stop and disable service
sudo systemctl stop linguflex@$USER
sudo systemctl disable linguflex@$USER

# Remove files
sudo rm -rf /opt/linguflex
sudo rm -rf /var/log/linguflex
sudo rm /etc/systemd/system/linguflex@.service
sudo rm /etc/pulse/client.conf.d/linguflex.conf
sudo rm /etc/logrotate.d/linguflex
sudo rm /usr/share/applications/linguflex.desktop

# Clean up system
sudo systemctl daemon-reload
sudo apt autoremove
```

## Additional Notes

### File Locations
- Main application: `/opt/linguflex`
- Logs: `/var/log/linguflex/`
- Service file: `/etc/systemd/system/linguflex@.service`
- Desktop entry: `/usr/share/applications/linguflex.desktop`
- Configuration: `~/.config/linguflex`

### Security Notes
- The service runs under user context for security
- Audio/display access is restricted to the user
- Logs are rotated daily (7-day retention)
- All paths use absolute references

### Performance Tips
- Use SSD for better model loading
- Enable GPU acceleration if available
- Keep system updated
- Monitor resource usage with `htop`

## Getting Help

1. Check logs:
   ```bash
   tail -f /var/log/linguflex/*.log
   ```

2. Run diagnostics:
   ```bash
   ./diagnose_linux.sh
   ```

3. Get system info:
   ```bash
   ./system_info.sh
   ```

4. Report issues:
   - Include log outputs
   - Describe steps to reproduce
   - List system specifications
   - Attach error messages