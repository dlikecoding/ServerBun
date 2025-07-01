#!/bin/bash

# Function to ask for user confirmation
confirm() {
    read -r -p "$1 [y/N] " response
    case "$response" in
        [yY][eE][sS]|[yY])
            true
            ;;
        *)
            false
            ;;
    esac
}

echo "Updating the system..."
sudo dnf -y update

echo "Upgrading the system..."
sudo dnf -y upgrade --refresh

echo "Installing micro/nano..."
sudo dnf -y install nano

#echo "Installing Python 3 pip..."
sudo dnf -y install python3-pip

echo "Stopping and disabling cockpit..."
sudo systemctl stop cockpit
sudo systemctl stop cockpit.socket
sudo systemctl mask cockpit
sudo systemctl daemon-reload

echo "Customizing ~/.bashrc..."
# Append customizations to ~/.bashrc
cat <<EOL >> ~/.bashrc

export PS1="\[\e[1;35m\]タレント\[\e[m\]\[\e[0;36m\]@Cloud\[\e[m\]\[\e[1;33m\][\w]$\[\e[m\] "
alias ll='ls -alF'

EOL

echo "Customization of ~/.bashrc completed."

# Reload ~/.bashrc for the changes to take effect
source ~/.bashrc


echo "Start Installing bun ..."
curl -fsSL https://bun.sh/install | bash


echo "Start Installing postgresql ..."
sudo dnf install -y https://download.postgresql.org/pub/repos/yum/reporpms/F-42-x86_64/pgdg-fedora-repo-latest.noarch.rpm
sudo dnf install -y postgresql17-server postgresql17-contrib
sudo /usr/pgsql-17/bin/postgresql-17-setup initdb
sudo systemctl enable postgresql-17
sudo systemctl start postgresql-17

echo "Start Installing FFMPEG & ImageMagick ..."
sudo dnf install https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm
sudo dnf install https://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm

sudo dnf -y install ffmpeg

sudo dnf -y install ImageMagick ImageMagick-heic

echo "Installing ExifTool..."
sudo dnf -y install perl-Image-ExifTool


sudo systemctl restart systemd-logind


confirm "Continue Installing Docker?" || exit 0
echo "Configuring Docker repositories and installing Docker..."
sudo dnf -y install dnf-plugins-core
sudo dnf-3 config-manager --add-repo https://download.docker.com/linux/fedora/docker-ce.repo
sudo dnf -y install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

echo "Adding the user to the docker group..."
sudo usermod -aG docker $USER

echo "Enabling Docker to start on boot..."
sudo systemctl enable --now docker
sudo systemctl start docker

# sudo reboot now # must reboot
pip3 install torch torchvision transformers pillow

#Install for location lookup base on coordinates
pip3 install reverse_geocoder --use-pep517