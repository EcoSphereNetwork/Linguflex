# Installing Linguflex on Ubuntu 24.04 LTS

This guide provides detailed instructions for installing and running Linguflex on Ubuntu 24.04 LTS.

## System Requirements

- Ubuntu 24.04 LTS
- At least 4GB RAM
- 10GB free disk space
- Internet connection
- Working audio input/output devices

## Installation Methods

### Method 1: Quick Installation (Desktop)

1. Clone the repository:
   ```bash
   git clone https://github.com/linguflex/Linguflex.git
   cd Linguflex
   ```

2. Run the installation script:
   ```bash
   sudo chmod +x install_ubuntu_24.04.sh
   sudo ./install_ubuntu_24.04.sh
   ```

3. Start Linguflex:
   - Either run `./start_linux.sh` from terminal
   - Or find "Linguflex" in your applications menu

### Method 2: Service Installation (Background)

1. Follow steps 1-2 from Method 1

2. Configure the service:
   ```bash
   sudo chmod +x configure_linux_service.sh
   sudo ./configure_linux_service.sh
   ```

3. Start the service:
   ```bash
   sudo systemctl start linguflex@$USER
   ```

4. (Optional) Enable at startup:
   ```bash
   sudo systemctl enable linguflex@$USER
   ```

## Troubleshooting

### Audio Issues

1. Check PulseAudio is running:
   ```bash
   pulseaudio --check
   ```

2. Restart PulseAudio if needed:
   ```bash
   pulseaudio -k
   pulseaudio --start
   ```

3. Verify microphone permissions:
   ```bash
   sudo usermod -a -G audio $USER
   ```

### Display Issues

1. Check X11 permissions:
   ```bash
   xhost +local:
   ```

2. Verify DISPLAY environment variable:
   ```bash
   echo $DISPLAY
   ```

### Service Issues

1. Check service status:
   ```bash
   sudo systemctl status linguflex@$USER
   ```

2. View logs:
   ```bash
   tail -f /var/log/linguflex/linguflex.log
   tail -f /var/log/linguflex/error.log
   ```

## Uninstallation

To completely remove Linguflex:

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

# Reload systemd
sudo systemctl daemon-reload
```

## Additional Notes

- The service runs under your user account to ensure proper access to audio and display
- Logs are rotated daily and kept for 7 days
- Configuration files are stored in `/opt/linguflex`
- The application can be run either as a desktop application or a system service
- All audio and display permissions are automatically configured during installation

## Support

If you encounter any issues:
1. Check the logs in `/var/log/linguflex/`
2. Verify all system dependencies are installed
3. Ensure your user has proper permissions
4. Try running the application in desktop mode for debugging