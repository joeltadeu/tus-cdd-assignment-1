#!/bin/bash

# Exit on error and unset variable
set -eu

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo "Please run as root or use sudo"
    exit 1
fi

# Detect package manager (dnf or yum)
if command -v dnf &> /dev/null; then
    PM=dnf
else
    PM=yum
fi

# Update package list
echo "Updating package list..."
$PM update -y

# Function to check and install
install_if_missing() {
    local cmd="$1"
    local pkg="$2"
    local desc="$3"

    if command -v "$cmd" &> /dev/null; then
        echo "$desc already installed, skipping..."
    else
        echo "Installing $desc..."
        $PM install -y "$pkg"
        echo "$desc installation completed."
    fi
}

# Install Git
install_if_missing git git "Git"

# Install Java 21 (Amazon Corretto)
install_if_missing java java-21-amazon-corretto-devel "Java 21"

# Install Maven
install_if_missing mvn maven "Maven"

echo "All tools are installed and ready."