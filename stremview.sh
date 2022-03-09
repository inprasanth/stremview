#!/usr/bin/bash

#LAMP Installation
echo -e "\n\n***✨Start Installation✨***\n"

sudo apt update -y
#apache2 installation
sudo apt install apache2 -y
#mysql-server
sudo apt install mysql-server -y 


sudo mysql_secure_installation  <<EOF
no
y
y
y
y
EOF

# php 7.4 installation

sudo apt-get install software-properties-common -y
sudo add-apt-repository  --yes  ppa:ondrej/php
sudo apt-get update
sudo apt-get install php7.4 -y
sudo apt-cache search php7.4 -y

sudo apt install php7.4-common php7.4-mysql php7.4-xml php7.4-xmlrpc php7.4-curl php7.4-gd php7.4-imagick php7.4-cli php7.4-dev php7.4-imap php7.4-mbstring php7.4-opcache php7.4-soap php7.4-zip php7.4-intl -y php7.4-fpm php7.4-redis
echo -e "\n\nConfig the Php 7.4\n"
 
sudo sed -i 's/max_execution_time = 30/max_execution_time = -1/g'  /etc/php/7.4/apache2/php.ini 
sudo sed -i 's/max_input_time = 60/max_input_time = -1/g'  /etc/php/7.4/apache2/php.ini 
sudo sed -i 's/memory_limit = 128M/memory_limit = -1/g'  /etc/php/7.4/apache2/php.ini 
sudo sed -i 's/post_max_size = 8M/post_max_size = 3000M/g'  /etc/php/7.4/apache2/php.ini 
sudo sed -i 's/upload_max_filesize = 2M/upload_max_filesize = 2048M/g'  /etc/php/7.4/apache2/php.ini 

 

sudo sed -i 's/DirectoryIndex index.html index.cgi index.pl index.php index.xhtml index.htm/DirectoryIndex index.php index.cgi index.pl index.html index.xhtml index.htm/g' /etc/apache2/mods-enabled/dir.conf


sudo systemctl restart php7.4-fpm.service 


echo -e "\n\n****✨✨Installing PHP & Requirements✨✨****\n"

ubntu=false

if [ "ubntu" == true ]
then
     sudo apt install phpmyadmin php-mbstring php-gettext 
else
     sudo apt update && sudo apt install phpmyadmin php-mbstring 
fi


echo -e "\n\n****✨Enabling Modules✨***\n"

sudo phpenmod mbstring

sudo a2enmod rewrite

sudo systemctl restart apache2

# Configure PhpMyAdmin   

sudo sed -i 's/AllowOverride None/AllowOverride All/g'  /etc/apache2/apache2.conf
 

sudo sh -c  'echo  "Include /etc/phpmyadmin/apache.conf" >> /etc/apache2/apache2.conf'


sudo service apache2 restart

sudo systemctl restart apache2

echo -e "\n\n***✨Composer installation✨***\n"
sudo apt-get install composer -y
cd ~
curl -sS https://getcomposer.org/installer -o composer-setup.php
sudo php composer-setup.php --install-dir=/usr/local/bin --filename=composer

sudo apt -y install curl

curl -sL https://deb.nodesource.com/setup_12.x | sudo bash -
sudo apt install nodejs -y

curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | sudo apt-key add -
echo "deb https://dl.yarnpkg.com/debian/ stable main" | sudo tee /etc/apt/sources.list.d/yarn.list
sudo apt update && sudo apt install yarn

#certbot certificate installation

sudo apt install certbot python3-certbot-apache -y

sudo apt-get update
sudo apt-get install python-certbot-apache
sudo apt-get install software-properties-common python-software-properties
#sudo add-apt-repository --yes ppa:certbot/certbot
sudo apt-get update

sudo npm install forever -g

# Redis && FFMPEG Install

echo -e "\n\n***✨Redis && FFMPEG Install✨***\n"
 
sudo snap install ffmpeg
# sudo add-apt-repository --yes ppa:jonathonf/ffmpeg-4
sudo apt update && sudo apt install ffmpeg libav-tools x264 x265 -y
sudo apt-get install ffmpeg -y
sudo add-apt-repository --yes ppa:chris-lea/redis-server 
sudo apt-get update
sudo apt-get install -y redis-server
sudo service redis-server start

#Backend 

echo "Project installation starting..."
echo "ssh key generating..."
#mkdir ~/.ssh
cd ~/.ssh
ssh-keygen
cat streamview-backend.pub
read -p "Do you copied the ssh key (y/n)?" 

cd ~
printf "Gitsource: "
read -r gitsource

git clone "$gitsource"

eval $(ssh-agent)
ssh-add ~/.ssh/streamview-backend

echo "Cloning the backend repo"

printf "Gitsource: "
read -r gitsource

git clone "$gitsource" 

echo "backend clone completed......";

cd ~/.ssh
ssh-keygen
cat streamview-frontend.pub
read -p "Do you copied the ssh key (y/n)?" yn

cd ~
printf "Gitsource: "
read -r gitsource

git clone "$gitsource"

eval $(ssh-agent)
ssh-add ~/.ssh/streamview-frontend

echo "Cloning the fronend repo"

printf "Gitsource: "
read -r gitsource

git clone "$gitsource" 

echo "fronend clone completed......";


cd streamview-backend-vu-package


yes | sudo composer update

sudo npm install

cp .env.example .env

sudo mysql <<EOF

ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY 'streamview@123';

FLUSH PRIVILEGES;

CREATE DATABASE streamview;

EOF

#env conf
    
sudo sed -i 's/APP_URL=/APP_URL=domain/g' .env
envpath=.env
read -p "Enter the admin Domain -): " domain
if [[ $domain != "" ]]; then
  replacement="https://$domain/"
  sed -i --expression "s@domain@$replacement@g" $envpath
fi

sudo sed -i 's/DB_PASSWORD=/DB_PASSWORD=streamview@123/g' .env

#Backend Configuration  

echo -e "\n\***✨Backend Configuration✨***\n"

sudo mkdir public/uploads public/default-json

sudo chmod 777 -R public/default-json public/uploads

sudo mkdir public/uploads/images public/uploads/videos public/uploads/smil public/uploads/ public/uploads/videos/original public/uploads/subtitles

sudo chmod 777 -R public/default-json public/uploads

sudo chmod -R 777 storage/ bootstrap public public/default-json public/uploads 

php artisan view:clear
php artisan cache:clear
php artisan migrate --seed
php artisan key:generate
yes | sudo composer dump-autoload
php artisan storage:link    
php artisan config:cache
sudo service apache2 restart
sudo npm install 

cd ~

# Frontend

cd streamview-frontend-package

sudo npm install 
echo -e "\n\n***✨Frontend Configuration✨***\n"

filepath=src/Environment.jsx
filepaths=src/components/Constant/constants.jsx
read -p "Enter the Admin Domain: " domain

if [[ $domain != "" ]]; then

    sed -i "s/adminview.streamhash.com/$domain/g"  $filepath

    sed -i "s/adminview.streamhash.com/$domain/g"  $filepaths
fi 

sudo npm run build --prod

sudo cp https_htaccess build/.htaccess

cd ~
#Create symlinks for html folder
echo -e "\n\n****✨Symlinks stepup✨****\n"
pwd

sudo ln -sf /home/streamview/streamview-backend-vu-package /var/www/html

sudo ln -sf /home/streamview/streamview-frontend-package /var/www/html

#VirtualHost Conf
echo -e "\n\n***✨VirtualHost Backend Configuration✨***\n"

cd /etc/apache2/sites-available 

sudo cp 000-default.conf streamview-backend.conf

sudo sed -i 's/#ServerName www.example.com/ServerName www.example.com/g' streamview-backend.conf

conffile=streamview-backend.conf
read -p "Enter the Admin Domain: " backenddomain
if [[ $backenddomain != "" ]]; then

    sudo  sed -i "s/www.example.com/$backenddomain/g"  $conffile
    replace="DocumentRoot /var/www/html/streamview-backend-vu-package/public"
    sudo  sed -i --expression  "s@DocumentRoot /var/www/html@$replace@g"  $conffile

fi 
#VirtualHost Conf
echo -e "\n\n***✨VirtualHost Frontend Configuration✨***\n"

sudo sed -i 's/#ServerName www.example.com/ServerName www.example.com/g' 000-default.conf

conffile=000-default.conf
read -p "Enter the User Domain: " frontenddomain
if [[ $frontenddomain != "" ]]; then

    sudo  sed -i "s/www.example.com/$frontenddomain/g"  $conffile
    replace="DocumentRoot /var/www/html/streamview-frontend-package/build"
    sudo  sed -i --expression  "s@DocumentRoot /var/www/html@$replace@g"  $conffile

fi
#backend virtualhost enabled 

sudo a2ensite streamview-backend.conf

 
sudo systemctl reload apache2

sudo service apache2 restart

# SSL Certificate Installation
echo -e "\n\n***✨SSL  Certificate Download✨***\n"

read -p "Enter you Admin Domain:" ssldomain


if [[ $ssldomain ]]; then

    sudo certbot --apache -d $ssldomain

fi

read -p "Enter you User Domain:"  ssldomains

if  [[ $ssldomains ]]; then

    sudo certbot --apache -d $ssldomains

  else

    echo "Please Try Again ---)"
fi

#tmux installation 

cd ~
sudo apt-get install tmux -y

wget https://adminview.streamhash.com/tmux.conf --no-check-certificate
mv tmux.conf ~/.tmux.conf
source ~/.bashrc


sudo echo 'tm() { tmux new -s "$1" ;}' >> ~/.bashrc 
sudo echo 'ta() { tmux attach -t "$1"; }' >> ~/.bashrc 
sudo echo 'tl() { tmux list-sessions; }' >> ~/.bashrc 
source ~/.bashrc
session="ara"
tmux new-session -s "$session"
   for i in {1..8}; do
     tmux new-window -t "$session:$i" -n "base"
   done

tmux select-window -t "$session:1"
tmux attach-session -t $session

echo "Complete the Installation.......);"

