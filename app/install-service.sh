#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SERVICE_FILE="$SCRIPT_DIR/shirabe-ui.service"

if [ ! -f "$SERVICE_FILE" ]; then
  echo "Error: shirabe-ui.service not found in $SCRIPT_DIR"
  exit 1
fi

echo "Installing Shirabe UI service..."
echo "Make sure you've edited shirabe-ui.service with your username and paths first!"
echo ""

sudo cp "$SERVICE_FILE" /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable shirabe-ui
sudo systemctl start shirabe-ui
sudo systemctl status shirabe-ui
