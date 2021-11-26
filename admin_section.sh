#REVERSE PROXY SECTION
echo "127.0.0.1 wedigitech.software-inside.it" >> /etc/hosts 
#REVERSE PROXY SECTION

#SOFTWARE INSTALLATION
distro=$(uname -n) 
if [ "$distro" = "pop-os" ]; 
then
    sh pop_os_installation.sh
else
    sh manjaro_admin_installation.sh
fi
#SOFTWARE INSTALLATION


#INSTALLING ANGULAR
npm install npm@latest -g
npm install -g @angular/cli
#INSTALLING ANGULAR
