#!/bin/bash

# This script will install an Nginx webserver and host a file, index.html over port 8080
# Author: Spencer Seebald 
# Supported OS's - Ubuntu (finished), RHEL (Unfinished), CentOS (Unfinished), SuSE (Unfinished)
# Overall TO-DOs:
#    -Add OS check
#    -Code for differences in different OS's
#    -Add more echo before and after each step so the user knows what is going on, 
#     what's being installed, and where we are in the install process 
#    -Complete TO-DOs listed in the code below


# Check to see if nginx is already installed. If it's not installed, 
# add the nginx/stable PPA to the respository, update our sources, 
# and install the newest stable build   

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

# Check to see if Git is installed. We need this to pull down the index.html from the Puppet repository

if [ "$(which git)" == "" ] ; then
    sudo apt-get install -y git-core
fi

# Set our current working directory

DIRECTORY=$(pwd) 
DIRECTORY+='/exercise-webpage'

# Check to make sure the git directory and file doesnt already exist. If they do not, pull down the index.html

if [ -d "$DIRECTORY" ]; then
    echo "Already downloaded"
else
    git clone https://github.com/puppetlabs/exercise-webpage
fi

# Create our web directories for our site

# TO-DO: Wrap in if block so we don't attempt to create the directories if they already exist

mkdir $HOME/nginx-data
mkdir $HOME/nginx-images

# Copy over index.html from the Puppet Git repo to our personal nginx web dir

cp exercise-webpage/index.html $HOME/nginx-data/

# Update permissions on the nginx default config file so we can update it without sudo permissions

sudo chown $USER:$USER /etc/nginx/sites-enabled/default

# To avoid causing any irrepairable damage to an already existing configuration (and because it's best practice)
# back up the current default configuration  

cp /etc/nginx/sites-enabled/default $HOME/nginx-data/default.old

# Append our own server group to set the port and data directories to the end of the file

# TO-DO: Add a check on the defualt config file and make sure no other sites are configured on port 8080. Also, 
# run a netstat to see if any services are hosted on 8080 already. Pass this to the user if there is.  

echo $"server {
      listen 8080;
        location / {
                root $HOME/nginx-data/;
        }
        location /images/ {
                root $HOME/nginx-images/;
        }
        }" >> /etc/nginx/sites-enabled/default

# Once we've add our site configuration, reload the nginx configuration file, and restart the service 

nginx -s reload
sudo service nginx restart
