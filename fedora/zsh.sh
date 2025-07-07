#install fonts and plugin for zsh
chmod +x like_manjaro_zsh.sh
./like_manjaro_zsh.sh
#set zsh as default
sudo usermod --shell $(which zsh) $USER
exec zsh

# install brew
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
# adding brew to .bashrc
echo >> ~/.bashrc
echo 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"' >> ~/.bashrc
echo >> ~/.zshrc
echo 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"' >> ~/.zshrc
eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
#installing from brew
brew install neofetch virt-manager libvirt qemu lazydocker jenv nvm

