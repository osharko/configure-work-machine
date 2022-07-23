#INIT
mkdir ~/init_tmp
cp -r . ~/init_tmp
#INIT

#SOFTWARE INSTALLATION
cd ~/init_tmp
sudo sh admin_section.sh

distro=$(uname -a) 
if [[ "$distro" =~ "MANJARO" ]]; 
then
    sh manjaro_user_installation.sh
    sudo systemctl enable teamviewerd.service
    sudo systemctl start libvirtd.service
fi

sudo usermod -aG docker $USER
#SOFTWARE INSTALLATION

#CONFIGURE_SSH_KEY
sh configure_ssh_key.sh
#CONFIGURE_SSH_KEY
