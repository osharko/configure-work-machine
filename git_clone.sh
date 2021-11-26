#CLONING GIT-REPO
cd ~ 
mkdir Code && cd Code 
mkdir Be-Solution && cd Be-Solution  
mkdir internal-proj && cd internal-proj

cd ~/Code/Be-Solution/internal-proj && mkdir wedigitech && cd wedigitech
git clone git@gitlab.com:internal-proj/wedigitech/wedigitech-be.git
git clone git@gitlab.com:internal-proj/wedigitech/wedigitech-compose.git 
git clone git@gitlab.com:internal-proj/wedigitech/wedigitech-data.git
git clone git@gitlab.com:internal-proj/wedigitech/wedigitech-fe.git 

cd ~/Code/Be-Solution/internal-proj && mkdir pmsa && cd pmsa
git clone git@gitlab.com:internal-proj/pmsa/pmsa-compose.git 
git clone git@gitlab.com:internal-proj/pmsa/pmsa-dos.git
git clone git@gitlab.com:internal-proj/pmsa/pmsa-fe.git

cd ~/Code/Be-Solution/internal-proj && mkdir wordpress-wedigitech && cd wordpress-wedigitech
git clone git@gitlab.com:internal-proj/wordpress-wedigitech/job_posting-java-be.git 
git clone git@gitlab.com:internal-proj/wordpress-wedigitech/job_posting-plugin.git 
git clone git@gitlab.com:internal-proj/wordpress-wedigitech/video-plugin.git 
git clone git@gitlab.com:internal-proj/wordpress-wedigitech/wordpress-compose.git 
#CLONING GIT-REPO