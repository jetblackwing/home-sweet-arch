#!/bin/bash

# This script sets up a Linux environment by updating the system,
# installing essential packages, and configuring user settings. 
# It is intended to be run on my own distributions.
# Usage: chmod +x linux-setup.sh && ./linux-setup.sh

echo "Starting Linux environment setup..."
echo "Copying setup script to specific directories..."

mkdir -p ~/.config/scripts
cp -rv *.sh ~/.config/scripts/
chmod +x ~/.config/scripts/*.sh
echo "Setup scripts copied to ~/.config/scripts/"
echo "Building desktop files..."
mkdir -p ~/.local/share/applications
cat <<EOF > ~/.local/share/applications/linux-setup.desktop
[Desktop Entry]
Type=Application
Name=Linux Setup
Exec=bash ~/.config/scripts/linux-setup.sh
Icon=utilities-terminal
Terminal=true
Categories=Utility;
EOF
echo "Desktop file created at ~/.local/share/applications/linux-setup.desktop"  

echo "Just to make sure, updating this system..."
sudo pacman -Syu --noconfirm
echo "System updated."