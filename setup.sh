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

NGINX_Dir="$(pwd)/nginx"

# Create our web directories for our site
    if [ -d $NGINX_Dir ]; then
        read -p "Directory $NGINX_Dir already exists - Please specify another directory: " NGINX_Dir
        NGINX_Dir="$(pwd)/$NGINX_Dir"
        mkdir $NGINX_Dir
    else
        mkdir $NGINX_Dir
    fi

    if [ -d "$NGINX_Dir/logs" ]; then
        echo "Directory already exists" >> $NGINX_Dir/logs/log.txt
    else
        mkdir $NGINX_Dir/logs
        echo "***********************" $(date) "************************" >> $NGINX_Dir/logs/log.txt
        echo "Creating directory: $NGINX_Dir/logs ... Success" >> $NGINX_Dir/logs/log.txt
    fi

    if [ -d "$NGINX_Dir/nginx-data" ]; then
        echo "Directory already exists" >> $NGINX_Dir/logs/log.tx
    else
        mkdir $NGINX_Dir/nginx-data
        echo "Creating directory: $NGINX_Dir/nginx-data ... Success" >> $NGINX_Dir/logs/log.txt
    fi

    if [ -d "$NGINX_Dir/nginx-images" ]; then
        echo "Directory already exists" >> $NGINX_Dir/logs/log.txt
    else
        mkdir $NGINX_Dir/nginx-images
        echo "Creating directory: $NGINX_Dir/nginx-images ... Success" >> $NGINX_Dir/logs/log.txt
    fi

# OS Check - Looking specifically for Ubuntu, RHEL, SuSE

is_Ubuntu=0
is_SuSE=0
is_RHEL=0

# Loop to determine OS type - To add more supported OS's, add new OS to for line and add logic for it
for STRING in 'Ubuntu' 'SuSE' 'Red Hat' 'CentOS' 'Fedora'
do
    if  grep -q "$STRING" /etc/*-release; then
        if [ "$STRING" == "Ubuntu" ]; then
            is_Ubuntu=1
            echo "Ubuntu/Debian install detected, beginning installation" >> $NGINX_Dir/logs/log.txt
            break
        elif [ "$STRING" == "SuSE" ]; then
            is_SuSE=1
            echo "SuSE install detected, beginning installation" >> $NGINX_Dir/logs/log.txt
            break
        else
            is_RHEL=1
            echo "Red Hat/Fedora/CentOS install detected, beginning installation" >> $NGINX_Dir/logs/log.txt
            break
        fi
    fi
done

# Check to see if nginx is already installed. If it's not installed, 
# add the nginx/stable PPA to the respository, update our sources, 
# and install the newest stable build   

if [ $is_Ubuntu == "1" ]; then
    if [ "$(which nginx)" == "" ] ; then
	if grep nginx /etc/apt/sources.list /etc/apt/sources.list.d/*; then
	    sudo apt-get install-y -q nginx
	    if [ "$(which nginx)" != "" ] ; then
		echo "Installing nginx ... Success" >> $NGINX_Dir/logs/log.txt
	    else
		echo "There was an error installing nginx" >> $NGINX_Dir/logs/log.txt
	    fi
	else
	    #TO-DO: Find build - Older builds might need a different PPA
	    sudo add-apt-repository -y ppa:nginx/stable
	    if grep nginx /etc/apt/sources.list.d/*; then
		sudo apt-get update -q
		sudo apt-get install -y -q nginx 
		echo "Installing nginx ... Success" >> $NGINX_Dir/logs/log.txt
	    else
		echo "PPA failed to be added" >> $NGINX_Dir/logs/log.txt
	    fi
	fi
    else
	echo "Nginx is installed" >> $NGINX_Dir/logs/log.txt
    fi

    # Check to see if Git is installed. We need this to pull down the index.html from the Puppet repository
    
    if [ "$(which git)" == "" ] ; then
	sudo apt-get install -y git-core
	echo "Installing git-core ... Success" >> $NGINX_Dir/logs/log.txt
    fi
    
    # Set our current working directory
    
    DIRECTORY=$(pwd) 
    DIRECTORY+='/exercise-webpage'
    
    # Check to make sure the git directory and file doesnt already exist. If they do not, pull down the index.html
    
    if [ -d "$DIRECTORY" ]; then
	echo "Already downloaded" >> $NGINX_Dir/logs/log.txt
    else
	git clone https://github.com/puppetlabs/exercise-webpage
	echo "Creating directory $DIRECTORY ... Success" >> $NGINX_Dir/logs/log.txt
    fi
    
    # Copy over index.html from the Puppet Git repo to our personal nginx web dir
    cp exercise-webpage/index.html $NGINX_Dir/nginx-data/
    echo "Copy puppet index.html from git to our data location for nginx" >> $NGINX_Dir/logs/log.txt

    # Update permissions on the nginx default config file so we can update it without sudo permissions
    sudo chown $USER:$USER /etc/nginx/sites-enabled/default
    echo "Updating permissions on /etc/nginx/sites-enabled/default to $USER:$USER ... Success" >> $NGINX_Dir/logs/log.txt
    
    # To avoid causing any irrepairable damage to an already existing configuration (and because it's best 
    # practice), back up the current default configuration  
    cp /etc/nginx/sites-enabled/default $NGINX_Dir/nginx-data/default.old
    echo "Default nginx server configuration backed up successfully to $NGINX_Dir/nginx-data.old" >> $NGINX_Dir/logs/log.txt

    # Append our own server group to set the port and data directories to the end of the file
    
    # TO-DO: Add a check on the defualt config file and make sure no other sites are configured on port 8080. 
    # Also, run a netstat to see if any services are hosted on 8080 already. Pass this to the user if there is.  
    
    echo $"server {
      listen 8080;
        location / {
                root $NGINX_Dir/nginx-data/;
        }
        location /images/ {
                root $NGINX_Dir/nginx-images/;
        }
        }" >> /etc/nginx/sites-enabled/default
    
    # Once we've add our site configuration, reload the nginx configuration file, and restart the service 
    
    sudo service nginx stop
    sudo service nginx start

    echo "All components successfully installed. Index.html is currently being hosted over port 8080"
fi
   
