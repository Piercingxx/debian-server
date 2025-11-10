#!/usr/bin/env bash
# Install Nvidia drivers and CUDA on Debian 13
# https://github.com/piercingxx

set -euo pipefail

# Verify we are running as root
if [[ $EUID -ne 0 ]]; then
	echo "This script must be run as root." >&2
	exit 1
fi


sudo apt install extrepo -y
extrepo update
sudo extrepo enable nvidia-cuda
sudo apt update
sudo apt install build-essential linux-headers-amd64 -y
sudo apt install nvidia-open-580 -y



#wget https://developer.download.nvidia.com/compute/cuda/13.0.2/local_installers/cuda-repo-debian12-13-0-local_13.0.2-580.95.05-1_amd64.deb
#sudo dpkg -i cuda-repo-debian12-13-0-local_13.0.2-580.95.05-1_amd64.deb
#sudo cp /var/cuda-repo-debian12-13-0-local/cuda-*-keyring.gpg /usr/share/keyrings/
#sudo apt-get update
#sudo apt-get -y install cuda-toolkit-13-0
#sudo apt-get -y install nvidia-driver


echo "Rebooting to apply changes..."
reboot
