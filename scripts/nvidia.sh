#!/usr/bin/env bash
# Install Nvidia drivers and CUDA on Debian 13
# https://github.com/piercingxx

set -euo pipefail

# Verify we are running as root
if [[ $EUID -ne 0 ]]; then
	echo "This script must be run as root." >&2
	exit 1
fi



echo "Rebooting to apply changes..."
reboot