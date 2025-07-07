# Enable docker
sudo systemctl --now enable docker
sudo usermod -aG docker $(whoami)
#Enable virt-d
sudo systemctl enable --now libvirtd
sudo usermod -aG libvirt $(whoami)

# sshd
sudo systemctl enable sshd --now
# xrdp
sudo systemctl enable xrdp --now
sudo firewall-cmd --new-zone=xrdp --permanent
sudo firewall-cmd --add-port=3389/tcp --permanent


flatpak install brave org.telegram.desktop com.thincast.client com.system76.Popsicle io.dbeaver.DBeaverCommunity io.beekeeperstudio.Studio -y
