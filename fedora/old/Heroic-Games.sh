#!/bin/bash

# Define the URL for the GitHub API releases endpoint
REPO="Heroic-Games-Launcher/HeroicGamesLauncher"
API_URL="https://api.github.com/repos/$REPO/releases/latest"

# Fetch the latest release data from GitHub API
echo "Fetching the latest release information..."
RELEASE_DATA=$(curl -s $API_URL)

# Extract the download URL for the RPM file
RPM_URL=$(echo $RELEASE_DATA | grep -oP '"browser_download_url": "\K(.*\.rpm)(?=")')

# Check if the RPM URL was found
if [ -z "$RPM_URL" ]; then
    echo "Failed to find the RPM download URL."
    exit 1
fi

# Download the RPM file
echo "Downloading the latest RPM from $RPM_URL..."
curl -L -o HeroicGamesLauncher.rpm $RPM_URL

# Install the RPM file
echo "Installing the RPM..."
sudo dnf install -y ./HeroicGamesLauncher.rpm

# Clean up
echo "Cleaning up..."
rm HeroicGamesLauncher.rpm

echo "Heroic-Games-Launcher has been updated successfully!"
