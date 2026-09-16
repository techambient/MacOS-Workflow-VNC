#!/bin/bash

# Assign parameters to readable variables
VNC_USER_PASSWORD="$1"
VNC_PASSWORD="$2"
NGROK_AUTH_TOKEN="$3"

# Disable spotlight indexing to optimize performance
sudo mdutil -i off -a

# Create new admin user account safely
sudo dscl . -create /Users/vncuser
sudo dscl . -create /Users/vncuser UserShell /bin/bash
sudo dscl . -create /Users/vncuser RealName "VNC User"
sudo dscl . -create /Users/vncuser UniqueID 1001
sudo dscl . -create /Users/vncuser PrimaryGroupID 80
sudo dscl . -create /Users/vncuser NFSHomeDirectory /Users/vncuser
sudo dscl . -passwd /Users/vncuser "$VNC_USER_PASSWORD"
sudo createhomedir -c -u vncuser > /dev/null

# Enable built-in Apple Remote Management / VNC server
sudo /System/Library/CoreServices/RemoteManagement/ARDAgent.app/Contents/Resources/kickstart -configure -allowAccessFor -allUsers -privs -all
sudo /System/Library/CoreServices/RemoteManagement/ARDAgent.app/Contents/Resources/kickstart -configure -clientopts -setvnclegacy -vnclegacy yes 

# Obfuscate and set the legacy VNC-only password string
echo "$VNC_PASSWORD" | perl -we 'BEGIN { @k = unpack "C*", pack "H*", "1734516E8BA8C5E2FF1C39567390ADCA"}; $_ = <>; chomp; s/^(.{8}).*/$1/; @p = unpack "C*", $_; foreach (@k) { printf "%02X", $_ ^ (shift @p || 0) }; print "\n"' | sudo tee /Library/Preferences/com.apple.VNCSettings.txt

# Start and activate VNC service parameters
sudo /System/Library/CoreServices/RemoteManagement/ARDAgent.app/Contents/Resources/kickstart -restart -agent -console
sudo /System/Library/CoreServices/RemoteManagement/ARDAgent.app/Contents/Resources/kickstart -activate

# Fixed: Install ngrok using modern Homebrew syntax
brew install --cask ngrok

# Authenticate ngrok and launch a background TCP tunnel on VNC port 5900
ngrok config add-authtoken "$NGROK_AUTH_TOKEN"
ngrok tcp 5900 &
