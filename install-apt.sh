#!/bin/bash

# Abyss Chat APT Repository Installer
# Run this script with: curl -sSL https://raw.githubusercontent.com/North-Abyss/abyss_chat/main/install-apt.sh | sudo bash

if [ "$EUID" -ne 0 ]; then
  echo "Please run as root (or use sudo)"
  exit 1
fi

echo "Setting up Abyss Chat APT Repository..."

# Remove old configurations to prevent duplicate source warnings
rm -f /etc/apt/sources.list.d/abysschat.list
rm -f /etc/apt/sources.list.d/abysschat.sources
rm -f /etc/apt/sources.list.d/abyss-chat.list
rm -f /etc/apt/sources.list.d/abyss-chat.sources

# Create the sources.list entry
cat <<EOF > /etc/apt/sources.list.d/abyss-chat.list
deb [trusted=yes] https://north-abyss.github.io/abyss_chat/apt/debian /
EOF

echo "Repository added. Updating apt cache..."
apt-get update

echo ""
echo "✅ Abyss Chat APT Repository configured successfully!"
echo "To install or update the app, run:"
echo "    sudo apt install abyss-chat"
echo ""
