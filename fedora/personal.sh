# 1Password repo
sudo rpm --import https://downloads.1password.com/linux/keys/1password.asc
sudo sh -c 'echo -e "[1password]\nname=1Password Stable Channel\nbaseurl=https://downloads.1password.com/linux/rpm/stable/\$basearch\nenabled=1\ngpgcheck=1\nrepo_gpgcheck=1\ngpgkey=\"https://downloads.1password.com/linux/keys/1password.asc\"" > /etc/yum.repos.d/1password.repo'
# Steam repo
sudo dnf install https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm -y
sudo dnf config-manager --enable fedora-cisco-openh264 -y
# Steam and 1password install
sudo dnf install 1password steam -y
# install tools for torrent release
sudo dnf install mediainfo mkvtoolnix -y
# Downloading Msty
cd ~/Applications
wget https://assets.msty.app/linux/rocm/Msty_x86_64_rocm.AppImage
cd
# Jellyfin
flatpak install flathub com.github.iwalton3.jellyfin-media-player -y
#Configuring ssh
mkdir ~/.ssh
chmod 755 ~/.ssh
chown $(whoami):$(whoami) ~/.ssh
cp authorized_keys id_rsa id_rsa.pub ~/.ssh/
chmod -R 600 ~/.ssh/*
chown -R $(whoami):$(whoami) ~/.ssh/*

#################CORECTRL#################
# # Create a polkit rule for CoreCtrl
# echo 'polkit.addRule(function(action, subject) {
#     if ((action.id == "org.corectrl.helper.init" ||
#          action.id == "org.corectrl.helperkiller.init") &&
#         subject.local == true && subject.active == true &&
#         subject.isInGroup("YOUR_USERNAME")) {
#         return polkit.Result.YES;
#     }
# });' | sudo tee /etc/polkit-1/rules.d/90-corectrl.rules
#
# # Replace YOUR_USERNAME with your actual username
# sudo sed -i 's/YOUR_USERNAME/$(whoami)/g' /etc/polkit-1/rules.d/90-corectrl.rules
#
# # Copy CoreCtrl desktop entry to autostart directory
# cp /usr/share/applications/org.corectrl.CoreCtrl.desktop ~/.config/autostart/
#
# # Set correct permissions for the polkit rule file
# sudo chown root:polkitd /etc/polkit-1/rules.d/90-corectrl.rules
# sudo chmod 644 /etc/polkit-1/rules.d/90-corectrl.rules
#################CORECTRL#################
