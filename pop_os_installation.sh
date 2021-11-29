#ADDING GO TO PATH
echo "export PATH=$PATH:/usr/local/bin/go/bin" >> ~/.bashrc
source ~/.bashrc
#ADDING GO TO PATH

#GO SECTION
cd ~
wget https://golang.org/dl/go1.17.3.linux-amd64.tar.gz 
rm -rf /usr/local/bin/go && tar -C /usr/local/bin -xzf ~/go1.*.tar.gz && rm ~/go1.*.tar.gz && chmod -R 777 /usr/local/bin/go
go install golang.org/x/tools/gopls@latest
#GO SECTION

#INSTALLING FLATPAK SOFTWARE
sh flatpak.sh
#INSTALLING FLATPAK SOFTWARE

#ADDING TO REPO SECTION
wget -O - https://deb.beekeeperstudio.io/beekeeper.key | apt-key add - 
wget -O - https://repo.fortinet.com/repo/7.0/ubuntu/DEB-GPG-KEY | apt-key add -
wget -O - https://packages.microsoft.com/keys/microsoft.asc | apt-key add -
echo "deb https://deb.beekeeperstudio.io stable main" >> /etc/apt/sources.list
echo "deb [arch=amd64] https://repo.fortinet.com/repo/7.0/ubuntu/ /bionic multiverse" >> /etc/apt/sources.list
echo "deb [arch=amd64] https://packages.microsoft.com/repos/vscode stable main" >> /etc/apt/sources.list
#ADDING TO REPO SECTION

#NODEJS SECTION
curl -sL https://deb.nodesource.com/setup_16.x | sudo bash -
#NODEJS SECTION

#APT SECTION
apt update 
apt remove libreoffice* geary -y
apt install xclip xsel gparted htop make net-tools openjdk-16-jdk maven forticlient beekeeper-studio code nodejs
apt upgrade -y && apt dist-upgrade -y && apt autoremove && apt purge
#APT SECTION

#DOCKER SECTION
curl -fsSL https://get.docker.com -o get-docker.sh && sh get-docker.sh && rm get-docker.sh 
curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose 
chmod +x /usr/local/bin/docker-compose 
#DOCKER SECTION
