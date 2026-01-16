#!/bin/bash

# An experimental setup for workaround with nvidia drivers on Arch Linux.
# For basic and stable environment, we use suggested nvidia driver from AUR repo.
# Usage: chmod +x nv-setup.sh && ./nv-setup.sh

set -e  # Exit on any error

echo "Starting NVIDIA driver setup for Arch Linux..."

# List of packages to install from AUR
PACKAGES=("nvidia-580xx-dkms" "nvidia-580xx-utils" "nvidia-580xx-settings")

# Temporary directory for cloning
TEMP_DIR=$(mktemp -d)
cd "$TEMP_DIR"

# Download and install nvidia-580xx-dkms
echo "Downloading nvidia-580xx-dkms from AUR..."
git clone "https://aur.archlinux.org/nvidia-580xx-dkms.git"
cd "nvidia-580xx-dkms"
echo "Compiling and installing nvidia-580xx-dkms..."
makepkg -si --noconfirm
cd ..

# Download and install nvidia-580xx-utils
echo "Downloading nvidia-580xx-utils from AUR..."
git clone "https://aur.archlinux.org/nvidia-580xx-utils.git"
cd "nvidia-580xx-utils"
echo "Compiling and installing nvidia-580xx-utils..."
makepkg -si --noconfirm
cd ..

# Download and install nvidia-580xx-settings
echo "Downloading nvidia-580xx-settings from AUR..."
git clone "https://aur.archlinux.org/nvidia-580xx-settings.git"
cd "nvidia-580xx-settings"
echo "Compiling and installing nvidia-580xx-settings..."
makepkg -si --noconfirm
cd ..

# Clean up
cd /
rm -rf "$TEMP_DIR"

echo "NVIDIA driver installation complete."
echo "You may need to reboot for changes to take effect."
echo "Consider blacklisting nouveau if not already done: echo 'blacklist nouveau' > /etc/modprobe.d/blacklist-nvidia-nouveau.conf"