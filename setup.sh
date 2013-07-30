#!/bin/bash

# This script will install an Nginx webserver and host a file, index.html over port 8080
# Author: Spencer Seebald 
# Supported OS's - Ubuntu [Debian], CentOS [RHEL]
# Overall TO-DOs:
#    -Code for differences in different OS's
#    -Complete TO-DOs listed in the code below
#    -Error handling?

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

# OS Check - Looking specifically for Ubuntu, RHEL flavor OS's
is_Ubuntu=0
is_RHEL=0

# Loop to determine OS type - To add more supported OS's, add new OS to for line and add logic for it
for STRING in 'Ubuntu' 'Red Hat' 'CentOS' 'Fedora' 'Debian'
do
    if grep -q "$STRING" /etc/*-release; then
        if [ "$STRING" == "Ubuntu" ] || [ "$STRING" == "Debian" ]; then
            is_Ubuntu=1
            echo "Ubuntu/Debian install detected, beginning installation" >> $NGINX_Dir/logs/log.txt
            break
        elif [ "$STRING" == "Fedora" ] || [ "$STRING" == "Red Hat" ] || [ "$STRING" == "CentOS" ]; then
            is_RHEL=1
            echo "Red Hat/Fedora/CentOS install detected, beginning installation" >> $NGINX_Dir/logs/log.txt
            break
        else
            echo "Unsupported OS detected. Program exitting" >> $NGINX_Dir/logs/log.txt
            break
        fi
    fi
done

# Check to see if nginx is already installed. If it's not installed, 
# add the nginx/stable PPA to the respository, update our sources, 
# and install the newest stable build   
if [ "$is_Ubuntu" -eq 1 ]; then
    STATUS=0
    
    while [ "$STATUS" -eq 0 ]
    do
	if hash nginx 2>/dev/null; then
            echo "NGINX already installed."
            STATUS="2"
	else
            if grep -q /etc/apt/sources.list /etc/apt/sources.list.d/*; then
		sudo apt-get install -y -q nginx
		STATUS=$?
            else
		RELEASESERVER="$(lsb_release -r)"
                RELEASESERVER=${RELEASESERVER:(-5):2}
		if [ "$RELEASESERVER" -ge 10 ] &&  [ "$RELEASESERVER" -le 11 ] ; then
		    sudo add-apt-repository -y ppa:nginx/stable
		    echo "Adding nginx/stable repository ... Success" >> $NGINX_Dir/logs/log.tx
		else
		    echo "deb http://ppa.launchpad.net/nginx/$nginx/ubuntu lucid main" > /etc/apt/sources.list.d/nginx-stable-lucid.list
		    apt-key adv --keyserver keyserver.ubuntu.com --recv-keys C300EE8C
		fi
		if grep -q nginx /etc/apt/sources.list.d/* /etc/apt/sources.list; then
		    sudo apt-get update -q
		    sudo apt-get install -y -q nginx 
		    STATUS=$?
		    if [ "$STATUS" -eq 0 ]; then
			echo "Installing nginx ... Success" >> $NGINX_Dir/logs/log.txt
			STATUS="2"
		    fi
		else
		    echo "PPA failed to be added" >> $NGINX_Dir/logs/log.txt
		fi    
		if [ "$STATUS" -eq 1 ] && [ $X -le 2]; then
		    # Try to install again, just in case.
		    STATUS="0"
		else
		    echo "Install failed!"
		    exit
		fi
	    fi
	fi
	# Check to see if Git is installed. We need this to pull down the index.html from the Puppet repository
	if hash git 2>/dev/null; then
	    echo "Git Installed"
	    STATUS="2"
	else 
	    sudo apt-get install -y git-core
	    STATUS=$?
	    if [ $STATUS -eq 0 ]; then
		echo "Installing git-core ... Success" >> $NGINX_Dir/logs/log.txt
		STATUS="2"
	    else
		echo "Install failed!"
	    fi
	fi
    done
    
    # Set our current working directory
    DIRECTORY="$(pwd)/exercise-webpage"
    
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
    echo "Default nginx server configuration backed up successfully to $NGINX_Dir/nginx-data/default.old" >> $NGINX_Dir/logs/log.txt

    # Append our own server group to set the port and data directories to the end of the file
    
    # TO-DO: Add a check on the defualt config file and make sure no other sites are configured on port 8080. 
    # Also, run a netstat to see if any services are hosted on 8080 already. Pass this to the user if there is.  

    if grep 8080 /etc/nginx/sites-enabled/default; then
	echo "There is already a site configured to use port 8080. Reconfigure this site and re-run the installer to save yourself from the wrath of cthulu"
    else
	echo $"server {
      listen 8080;
        location / {
                root $NGINX_Dir/nginx-data/;
        }
        location /images/ {
                root $NGINX_Dir/nginx-images/;
        }
        }" >> /etc/nginx/sites-enabled/default
    fi
    # Once we've add our site configuration, reload the nginx configuration file, and restart the service 
    
    sudo service nginx stop
    sudo service nginx start

    echo "All components successfully installed. Index.html is currently being hosted over port 8080"
fi

if [ $is_RHEL -eq 1 ]; then
    STATUS=0
    
    while [ $STATUS -eq 0 ]
    do
	if hash nginx 2>/dev/null; then
            echo "NGINX already installed."
            STATUS="1"
	else
            if grep -q nginx /etc/yum.repos.d/*; then
		sudo yum check-update
		sudo yum install -y nginx
		STATUS=$?
            else
		RELEASESERVER="$(lsb_release -r)"
		RELEASESERVER=${RELEASESERVER:(-3):1}
		
		echo $"[nginx]
                           name=nginx repo
                           baseurl=http://nginx.org/packages/rhel/$RELEASESERVER/\$basearch/
                           gpgcheck=0
                           enabled=1" >> /$HOME/nginx.repo
		
		sudo cp -r nginx.repo /etc/yum.repos.d/
		sudo yum check-update
		sudo yum install -y nginx
		STATUS=$?
            fi
	    
	    if hash git 2>/dev/null; then
		sudo yum install -y git-core
		STATUS=$?
		echo "Installing git-core ... Success" >> $NGINX_Dir/logs/log.txt
	fi
	    
            if [ $STATUS -eq 1 ] && [ $X -le 2]; then
		# Try to install again, just in case.
		STATUS=0
            else
		echo "Install failed!"
            exit
            fi
	fi
    done
    
    # Set our current working directory
    DIRECTORY="$(pwd)/exercise-webpage"
    
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
    echo "Updating permissions on /etc/nginx/conf.d/default.conf to $USER:$USER ... Success" >> $NGINX_Dir/logs/\
log.txt
    
    # To avoid causing any irrepairable damage to an already existing configuration (and because it's best
    # practice), back up the current default configuration
    cp /etc/nginx/conf.d/default.conf $NGINX_Dir/nginx-data/default.conf.old
    echo "Default nginx server configuration backed up successfully to $NGINX_Dir/nginx-data/default.conf.old" >> $NGINX_Dir/lo\
gs/log.txt
    
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
