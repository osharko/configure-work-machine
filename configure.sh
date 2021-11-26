#INIT
mkdir ~/init_tmp
cp *.sh ~/init_tmp
#INIT

#SOFTWARE INSTALLATION
cd ~/init_tmp
sudo sh admin_section.sh

distro=$(uname -n) 
if [ "$distro" = "manjaro-gnome" ]; 
then
    sh manjaro_user_installation.sh
    cd ~
    sudo rm -r ~/yay-git
fi

sudo usermod -aG docker $USER
#SOFTWARE INSTALLATION

#CONFIGURE_SSH_KEY
sh configure_ssh_key.sh
#CONFIGURE_SSH_KEY

#CLONING GIT-REPO
sh git_clone.sh
#CLONING GIT-REPO
