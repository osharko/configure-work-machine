#REVERSE PROXY SECTION
#echo "127.0.0.1 wedigitech.software-inside.it" >> /etc/hosts 
#REVERSE PROXY SECTION

#SOFTWARE INSTALLATION
distro=$(uname -a) 
if [[ "$distro" = "Ubuntu" ]]; 
then
    sh pop_os_installation.sh
fi

if [[ "$distro" =~ "MANJARO" ]]; 
then
    sh manjaro_admin_installation.sh
    systemctl enable --now docker
fi
#SOFTWARE INSTALLATION


#INSTALLING ANGULAR
npm install npm@latest -g
npm install -g @angular/cli
#INSTALLING ANGULAR
