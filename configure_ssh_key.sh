#CREATING GIT SSH-KEY
mkdir ~/.ssh && cd ~/.ssh
ssh-keygen -f id_rsa -t rsa -N ''
#CREATING GIT SSH-KEY

#ASKING FOR GIT SSH-KEY
cat ~/.ssh/id_rsa.pub | xclip -sel clip
echo ""
echo "Copy the token provided into the clipboard to the opened gitlab repos:"
echo ""
echo ""
sleep 3
xdg-open https://gitlab.com/-/profile/keys
echo ""
echo ""
sleep 2
clear
echo "Copy the token provided into the clipboard to the opened gitlab repos:"

while true
do
    read -p "Have you inserted the new token to the opened repos? [y/n]" answer
    case $answer in
        [yY]* ) break;;

        [nN]* ) echo "Just do it";;

        * ) clear;
            echo "Please provide one of the letter provided into the following brackets [yn]";;
    esac
done
#ASKING FOR GIT SSH-KEY