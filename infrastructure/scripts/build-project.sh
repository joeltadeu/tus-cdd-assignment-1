#!/bin/bash
set -euo pipefail

REPO_URL="https://github.com/joeltadeu/tus-cdd-assignment-1.git"
TARGET_DIR="tus-cdd-assignment-1"

# Check if git is installed
if ! command -v git &> /dev/null; then
    echo "Error: git not found. Please install git first."
    exit 1
fi

# Check if mvn is installed
if ! command -v mvn &> /dev/null; then
    echo "Error: Maven (mvn) not found. Please install Maven first."
    exit 1
fi

# Clone repo if not already cloned
if [ -d "$TARGET_DIR" ]; then
    echo "Directory '$TARGET_DIR' already exists. Skipping clone."
else
    echo "Cloning repository..."
    git clone "$REPO_URL" "$TARGET_DIR"
fi

# Enter the project directory
cd "$TARGET_DIR"

# (Optional) check out a particular branch or tag if needed
# git checkout some-branch

# Build with Maven
echo "Building project with Maven..."
mvn clean install

echo "Build completed."