# java
mkdir ~/.nvm

for file in ~/.profile ~/.bashrc ~/.zshrc; do
	echo '#nvm' >> "$file"
	echo 'export NVM_DIR="$HOME/.nvm"' >> "$file"
	echo '[ -s "/home/linuxbrew/.linuxbrew/opt/nvm/nvm.sh" ] && \. "/home/linuxbrew/.linuxbrew/opt/nvm/nvm.sh"  # This loads nvm' >> "$file"
	echo '[ -s "/home/linuxbrew/.linuxbrew/opt/nvm/etc/bash_completion.d/nvm" ] && \. "/home/linuxbrew/.linuxbrew/opt/nvm/etc/bash_completion.d/nvm"  # This loads nvm bash_completion' >> "$file"
	  
	echo '#jenv' >> "$file"
	echo 'PATH="$HOME/.jenv/bin:$PATH"' >> "$file"
	echo 'eval "$(jenv init -)"' >> "$file"

	source "$file"
done


exec $SHELL -l
eval "$(jenv init -)"
jenv enable-plugin export
exec $SHELL -l

# downlod amazon corretto
sudo mkdir -p /usr/share/jdks
sudo chmod -R 777 /usr/share/jdks
sudo chown -R $(whoami):$(whoami) /usr/share/jdks

#jdk 8
mkdir -p /usr/share/jdks/jdk-8
wget -O - https://corretto.aws/downloads/latest/amazon-corretto-8-x64-linux-jdk.tar.gz | tar -xz --strip-components=1 -C /usr/share/jdks/jdk-8
jenv add /usr/share/jdks/jdk-8
#jdk 21
mkdir -p /usr/share/jdks/jdk-21
wget -O - https://corretto.aws/downloads/latest/amazon-corretto-21-x64-linux-jdk.tar.gz | tar -xz --strip-components=1 -C /usr/share/jdks/jdk-21
jenv add /usr/share/jdks/jdk-21
jenv global 21



# node
nvm install 20
