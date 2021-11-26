#INSTALLING YAY
cd ~
git clone https://aur.archlinux.org/yay-git.git && cd yay-git
makepkg -si
cd ~
#INSTALLING YAY

#INSTALLING AUR
yay --save --nocleanmenu --nodiffmenu

yay -S forticlient-vpn beekeeper-studio-bin visual-studio-code-bin telegram-desktop-bin postman-bin sublime-text-4 wps-office teams
#INSTALLING AUR
