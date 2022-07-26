#PACMAN SECTION
pacman -Syuu --noconfirm

pacman -S --noconfirm jenv yay nvm binutils git xclip xsel gparted htop make net-tools maven docker docker-compose popsicle iputils go openfortivpn corectrl qemu qemu-headless virt-manager

pacman -Scc --noconfirm
#PACMAN SECTION

#VPN SECTION
cd vpn

echo """
### configuration file for openfortivpn, see man openfortivpn(1) ###

host = 93.47.150.156
port = 10443
username = your.username
password = your.password

trusted-cert = 08320e722e19ccb087942bf159a4f9495f4696c94608d3f2de636288e34b9749
""" > /etc/openfortivpn/config

cp stop-vpn.sh start-vpn.sh /usr
cp start-vpn.service /etc/systemd/system
systemctl start start-vpn.service
cd ..
#VPN SECTION
