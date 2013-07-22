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

cp /etc/nginx/sites-enabled/default /etc/nginx/sites-enabled/default.old

echo $"server {
      listen 8080;
        location / {
                root /data/www;
        }
        location /images/ {
                root /data;
        }
        }" >> /etc/nginx/sites-enabled/default
