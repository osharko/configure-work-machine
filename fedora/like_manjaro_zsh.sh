source=~/manjaro-zsh-config;

update_permission()
{
    dest=$1
    sudo chmod -R 777 $dest;
    sudo chown -R $(whoami):$(whoami) $dest;
}

copy_to_zsh_folder()
{
    base_dest=/usr/share/zsh;
    source=$1;
    input=$2;

    sudo cp $source/$2 $base_dest/$2;
    update_permission $base_dest/$2
}

dest=/usr/share/zsh;
sudo rm -rf ~/.zshrc $dest/manjaro-zsh-config $dest/manjaro-zsh-prompt $dest/p10k-portable.zsh $dest/p10k.zsh $dest/zsh-maia-prompt;

git clone https://github.com/Chrysostomus/manjaro-zsh-config $source;
cp $source/.zshrc ~/.zshrc;
copy_to_zsh_folder $source manjaro-zsh-config;
copy_to_zsh_folder $source manjaro-zsh-prompt;
copy_to_zsh_folder $source p10k-portable.zsh;
copy_to_zsh_folder $source p10k.zsh;
copy_to_zsh_folder $source zsh-maia-prompt;
rm -rf $source

dest=/usr/share/zsh/plugins;
sudo rm -rf $dest
sudo mkdir $dest;
update_permission $dest
git clone https://github.com/zsh-users/zsh-history-substring-search $dest/zsh-history-substring-search;
git clone https://github.com/zsh-users/zsh-syntax-highlighting $dest/zsh-syntax-highlighting;
git clone https://github.com/zsh-users/zsh-autosuggestions $dest/zsh-autosuggestions;


dest=/usr/share/zsh-theme-powerlevel10k;
sudo rm -rf $dest;
sudo git clone https://github.com/romkatv/powerlevel10k $dest;
update_permission $dest

dest=~/.local/share/fonts/
mkdir -p $dest
wget https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Regular.ttf -O $dest/Regular.ttf
wget https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Bold.ttf -O $dest/Bold.ttf
wget https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Italic.ttf -O $dest/Italic.ttf
wget https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Bold%20Italic.ttf -O $dest/BoldItalic.ttf
fc-cache -f -v

echo "on your terminal profile, change font to Meslog"
echo "run zsh, then 'p10k configure' to finally perform the last changes"
