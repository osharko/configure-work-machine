# remove libreoffice
sudo dnf remove libreoffice-math libreoffice-calc libreoffice-draw libreoffice-writer libreoffice-core -y
# Brave
sudo dnf install dnf-plugins-core
sudo dnf config-manager addrepo --from-repofile=https://brave-browser-rpm-release.s3.brave.com/brave-browser.repo
# Sublimetext repo
sudo rpm -v --import https://download.sublimetext.com/sublimehq-rpm-pub.gpg
sudo dnf config-manager addrepo --from-repofile=https://download.sublimetext.com/rpm/stable/x86_64/sublime-text.repo
# Docker
sudo dnf -y install dnf-plugins-core
sudo dnf config-manager addrepo --from-repofile=https://download.docker.com/linux/fedora/docker-ce.repo
# Vscode Repo
sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
echo -e "[code]\nname=Visual Studio Code\nbaseurl=https://packages.microsoft.com/yumrepos/vscode\nenabled=1\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc" | sudo tee /etc/yum.repos.d/vscode.repo > /dev/null
# update system
sudo dnf update -y
sudo dnf group install development-tools -y
sudo dnf install git-core xrdp obs-studio gparted obs-studio timeshift corectrl gcc htop make zsh go coreutils iputils net-tools binutils timeshift -y
# installing software from added repositories
sudo dnf install sublime-text docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin brave-browser code -y

if [ "$DESKTOP_SESSION" == "gnome" ]; then
    flatpak install flathub com.mattjakeman.ExtensionManager -y
    
    	# original comment https://unix.stackexchange.com/a/707840

	array=( 
	# https://extensions.gnome.org/extension/4839/clipboard-history/
	https://extensions.gnome.org/extension-data/clipboard-historyalexsaveau.dev.v46.shell-extension.zip
	# https://extensions.gnome.org/extension/1160/dash-to-panel/
	https://extensions.gnome.org/extension-data/dash-to-paneljderose9.github.com.v68.shell-extension.zip
	# https://extensions.gnome.org/extension/7065/tiling-shell/
	https://extensions.gnome.org/extension-data/tilingshellferrarodomenico.com.v54.shell-extension.zip
	# https://extensions.gnome.org/extension/6807/system-monitor/
	https://extensions.gnome.org/extension-data/system-monitorgnome-shell-extensions.gcampax.github.com.v9.shell-extension.zip
	# https://extensions.gnome.org/extension/7/removable-drive-menu/
	https://extensions.gnome.org/extension-data/drive-menugnome-shell-extensions.gcampax.github.com.v67.shell-extension.zip
	)

	for i in "${array[@]}"
	do
	    wget $i -O temp.zip
	    gnome-extensions install --force temp.zip
	    rm temp.zip
	done


	EXTENSIONS=$(gnome-extensions list)

	# for EXTENSION in $EXTENSIONS; do
	#    gnome-extensions enable "$EXTENSION"
	# done
fi

