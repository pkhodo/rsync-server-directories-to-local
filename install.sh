#!/bin/bash
# Simple installation script for Server Sync Tool
# Because manual setup is so 2020

set -euo pipefail

REPO_URL="https://github.com/pkhodo/rsync-server-directories-to-local.git"
INSTALL_DIR="${1:-$HOME/.local/bin/server-sync}"

echo "🚀 Installing Server Sync Tool..."
echo ""

# Check if git is installed
if ! command -v git &> /dev/null; then
    echo "❌ Error: git is not installed. Please install git first."
    exit 1
fi

# Create install directory
echo "📁 Creating installation directory: $INSTALL_DIR"
mkdir -p "$INSTALL_DIR"

# Clone or update repository
if [ -d "$INSTALL_DIR/.git" ]; then
    echo "🔄 Repository exists, updating..."
    cd "$INSTALL_DIR"
    git pull
else
    echo "📥 Cloning repository..."
    git clone "$REPO_URL" "$INSTALL_DIR"
    cd "$INSTALL_DIR"
fi

# Make script executable
chmod +x sync.sh

# Copy example config if it doesn't exist
if [ ! -f "$INSTALL_DIR/sync-config.txt" ]; then
    echo "📋 Creating config file from example..."
    cp sync-config.txt.example sync-config.txt
fi

echo ""
echo "✅ Installation complete!"
echo ""
echo "Next steps:"
echo "  1. Edit $INSTALL_DIR/sync.sh and set SERVER and REMOTE_BASE"
echo "  2. Edit $INSTALL_DIR/sync-config.txt with your folder mappings"
echo "  3. Run: $INSTALL_DIR/sync.sh (dry-run mode)"
echo ""
echo "💡 Tip: Add an alias to your ~/.zshrc or ~/.bashrc:"
echo "  alias syncserver='cd $INSTALL_DIR && ./sync.sh'"
echo "  alias syncserver-now='cd $INSTALL_DIR && SYNC_DRY_RUN=0 ./sync.sh'"

