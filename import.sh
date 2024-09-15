# Kernel Repo
sudo rpm --import https://www.elrepo.org/RPM-GPG-KEY-elrepo.org
sudo dnf install https://www.elrepo.org/elrepo-release-9.el9.elrepo.noarch.rpm -y
# Microsoft edge repo
sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
sudo dnf config-manager --add-repo https://packages.microsoft.com/yumrepos/edge
# Vscode Repo
sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
echo -e "[code]\nname=Visual Studio Code\nbaseurl=https://packages.microsoft.com/yumrepos/vscode\nenabled=1\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc" | sudo tee /etc/yum.repos.d/vscode.repo > /dev/null
# 1Password repo
sudo rpm --import https://downloads.1password.com/linux/keys/1password.asc
sudo sh -c 'echo -e "[1password]\nname=1Password Stable Channel\nbaseurl=https://downloads.1password.com/linux/rpm/stable/\$basearch\nenabled=1\ngpgcheck=1\nrepo_gpgcheck=1\ngpgkey=\"https://downloads.1password.com/linux/keys/1password.asc\"" > /etc/yum.repos.d/1password.repo'
# Sublimetext repo
sudo rpm -v --import https://download.sublimetext.com/sublimehq-rpm-pub.gpg
sudo dnf config-manager --add-repo https://download.sublimetext.com/rpm/stable/x86_64/sublime-text.repo
# Docker repo
sudo dnf config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
# Install everything related above
sudo dnf --enablerepo=elrepo-kernel install kernel-ml 
# kernel-ml-core kernel-ml-headers kernel-ml-modules kernel-ml-modules-extra -y
sudo dnf install 1password microsoft-edge-stable code htop git sublime-text docker-ce docker-ce-cli containerd.io docker-compose-plugin gcc gparted binutils make net-tools iputils go make qemu-kvm libvirt virt-manager virt-install epel-release -y

# Enable docker
sudo systemctl --now enable docker
sudo usermod -aG docker $(whoami)
#Enable virt-d
sudo systemctl enable --now libvirtd
sudo usermod -aG libvirt $(whoami)

#curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.1/install.sh | TERMINAL
# Flatpak install
flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo

flatpak install flathub io.dbeaver.DBeaverCommunity -y
flatpak install flathub org.telegram.desktop -y
flatpak install flathub com.getpostman.Postman -y
flatpak install flathub com.wps.Office -y
flatpak install flathub com.system76.Popsicle -y
