#!/bin/bash

if [ "$(which nginx)" == "" ] ; then
    if grep nginx /etc/apt/sources.list /etc/apt/sources.list.d/*; then
	sudo apt-get install nginx
    else
	sudo add-apt-repository -y ppa:nginx/stable
	if grep nginx /etc/apt/sources.list.d/*; then
	    sudo apt-get update
	    sudo apt-get install -y nginx 
	else
	    echo "PPA failed to be added"
	fi
    fi
else
    echo "Nginx is installed"
fi

if [ "$(which git)" == "" ] ; then
    sudo apt-get install -y git-core
fi

DIRECTORY=$(pwd) 
DIRECTORY+='/exercise-webpage'

if [ -d "$DIRECTORY" ]; then
    echo "Already downloaded"
else
    git clone https://github.com/puppetlabs/exercise-webpage
fi

mkdir $HOME/nginx-data
mkdir $HOME/nginx-images
cp exercise-webpage/index.html $HOME/nginx-data/

sudo chown $USER:$USER /etc/nginx/sites-enabled/default

echo $"server {
      listen 8080;
        location / {
                root $HOME/nginx-data/;
        }
        location /images/ {
                root $HOME/nginx-images/;
        }
        }" >> /etc/nginx/sites-enabled/default

nginx -s reload
sudo service nginx restart
