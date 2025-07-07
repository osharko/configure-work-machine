# Install everything related above
###sudo dnf --enablerepo=elrepo-kernel install kernel-ml
# kernel-ml-core kernel-ml-headers kernel-ml-modules kernel-ml-modules-extra -y
###sudo dnf install 1password microsoft-edge-stable code sublime-text docker-ce docker-ce-cli containerd.io docker-compose-plugin epel-release -y
# Kernel Repo
# sudo rpm --import https://www.elrepo.org/RPM-GPG-KEY-elrepo.org
# sudo dnf install https://www.elrepo.org/elrepo-release-9.el9.elrepo.noarch.rpm -y
# remove libreoffice
sudo dnf remove libreoffice-math libreoffice-calc libreoffice-draw libreoffice-writer libreoffice-core
# update system
sudo dnf update
# install base packages
sudo dnf install neofetch htop git obs-studio zsh gcc gparted binutils make net-tools iputils go make qemu-kvm libvirt corectrl kate virt-manager timeshift xrdp virt-install -y

# Sublimetext repo
sudo rpm -v --import https://download.sublimetext.com/sublimehq-rpm-pub.gpg
sudo dnf config-manager --add-repo https://download.sublimetext.com/rpm/stable/x86_64/sublime-text.repo
sudo dnf install sublime-text -y

# Docker repo
sudo dnf -y install dnf-plugins-core
sudo dnf config-manager --add-repo https://download.docker.com/linux/fedora/docker-ce.repo
sudo dnf -y install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Enable docker
sudo systemctl --now enable docker
sudo usermod -aG docker $(whoami)
#Enable virt-d
sudo systemctl enable --now libvirtd
sudo usermod -aG libvirt $(whoami)


# Microsoft edge repo
sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
sudo dnf config-manager --add-repo https://packages.microsoft.com/yumrepos/edge
# Vscode Repo
sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
echo -e "[code]\nname=Visual Studio Code\nbaseurl=https://packages.microsoft.com/yumrepos/vscode\nenabled=1\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc" | sudo tee /etc/yum.repos.d/vscode.repo > /dev/null
# install above
sudo dnf install microsoft-edge-stable code -y


# sshd
sudo systemctl enable sshd --now
# xrdp
sudo systemctl enable xrdp --now
sudo firewall-cmd --new-zone=xrdp --permanent
sudo firewall-cmd --add-port=3389/tcp --permanent

# install AppImageLauncher to integrate AppImage inside the app launcher
sudo dnf install https://github.com/TheAssassin/AppImageLauncher/releases/download/v2.2.0/appimagelauncher-2.2.0-travis995.0f91801.x86_64.rpm
sudo mkdir -p ~/Applications
cd ~/Applications
wget https://github.com/pop-os/popsicle/releases/download/1.3.3/Popsicle_USB_Flasher-1.3.3-x86_64.AppImage
wget https://github.com/suciptoid/postman-appimage/releases/download/continous/Postman-11.13.0-x86_64.AppImage
wget https://github.com/beekeeper-studio/beekeeper-studio/releases/download/v4.6.8/Beekeeper-Studio-4.6.8.AppImage
wget https://github.com/ONLYOFFICE/appimage-desktopeditors/releases/download/v8.1.1/DesktopEditors-x86_64.AppImage
wget https://github.com/valicm/dbeaver-ce-appimage/releases/download/latest/dbeaver-ce-x86_64.AppImage
cd

#curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.1/install.sh | $TERMINAL
# Flatpak install
flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo

#flatpak install flathub io.dbeaver.DBeaverCommunity -y
flatpak install flathub org.telegram.desktop -y
flatpak install flathub com.thincast.client -y
# flatpak install flathub com.getpostman.Postman -y
# flatpak install flathub com.wps.Office -y
# flatpak install flathub com.system76.Popsicle -y

#################JAVA#################
# jenv
git clone https://github.com/jenv/jenv.git ~/.jenv
# Shell: bash
echo 'export PATH="$HOME/.jenv/bin:$PATH"' >> ~/.bash_profile
echo 'eval "$(jenv init -)"' >> ~/.bash_profile
# Shell: zsh
echo 'export PATH="$HOME/.jenv/bin:$PATH"' >> ~/.zshrc
echo 'eval "$(jenv init -)"' >> ~/.zshrc
exec $SHELL -l
eval "$(jenv init -)"
jenv enable-plugin export
exec $SHELL -l

# downlod amazon corretto
sudo mkdir -p /usr/share/jdks
sudo chmod -R 777 /usr/share/jdks
sudo chown -R $(whoami):$(whoami) /usr/share/jdks
#jdk 8
mkdir -p /usr/share/jdks/jdk-8
wget -O - https://corretto.aws/downloads/latest/amazon-corretto-8-x64-linux-jdk.tar.gz | tar -xz --strip-components=1 -C /usr/share/jdks/jdk-8
jenv add /usr/share/jdks/jdk-8
jenv global 1.8
#jdk 11
mkdir -p /usr/share/jdks/jdk-11
wget -O - https://corretto.aws/downloads/latest/amazon-corretto-11-x64-linux-jdk.tar.gz | tar -xz --strip-components=1 -C /usr/share/jdks/jdk-11
jenv add /usr/share/jdks/jdk-11
#jdk 17
mkdir -p /usr/share/jdks/jdk-17
wget -O - https://corretto.aws/downloads/latest/amazon-corretto-17-x64-linux-jdk.tar.gz | tar -xz --strip-components=1 -C /usr/share/jdks/jdk-17
jenv add /usr/share/jdks/jdk-17
#jdk 21
mkdir -p /usr/share/jdks/jdk-21
wget -O - https://corretto.aws/downloads/latest/amazon-corretto-21-x64-linux-jdk.tar.gz | tar -xz --strip-components=1 -C /usr/share/jdks/jdk-21
jenv add /usr/share/jdks/jdk-21
# maven
mkdir -p /usr/share/jdks/maven-3.9.9
wget -O - https://dlcdn.apache.org/maven/maven-3/3.9.9/binaries/apache-maven-3.9.9-bin.tar.gz | tar -xz --strip-components=1 -C /usr/share/jdks/maven-3.9.9
echo 'export PATH="/usr/share/jdks/maven-3.9.9/bin:$PATH"' | sudo tee -a /etc/profile
#################JAVA#################

#################NODE#################
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash
echo 'export NVM_DIR="$([ -z "${XDG_CONFIG_HOME-}" ] && printf %s "${HOME}/.nvm" || printf %s "${XDG_CONFIG_HOME}/nvm")" [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"' >> ~/.zshrc
echo 'export NVM_DIR="$([ -z "${XDG_CONFIG_HOME-}" ] && printf %s "${HOME}/.nvm" || printf %s "${XDG_CONFIG_HOME}/nvm")" [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"' >> ~/.bash_profile
exec $SHELL -l
nvm install 20
#################NODE#################

#################APPIMAGE#################
mkdir ~/Applications
cd ~/Applications
wget https://github.com/TheAssassin/AppImageLauncher/releases/download/v2.2.0/appimagelauncher-2.2.0-travis995.0f91801.x86_64.rpm
sudo dnf install ./appimagelauncher-2.2.0-travis995.0f91801.x86_64.rpm
rm ./appimagelauncher-2.2.0-travis995.0f91801.x86_64.rpm
echo 'NOW DOWNLOAD BEEKEPER AND PUT IT IN ~/Applications from https://www.beekeeperstudio.io/download/?ext=AppImage&arch=x86_64&type=&edition=community'
#################APPIMAGE#################
