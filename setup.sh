#!/bin/bash
# Simple setup.sh for configuring Ubuntu 12.04 LTS EC2 instance
# for headless setup. 

# Install nvm: node-version manager
# https://github.com/creationix/nvm
#sudo -s

sudo add-apt-repository ppa:nginx/$nginx
sudo apt-get update
sudo apt-get install -y nginx

git clone https://github.com/puppetlabs/exercise-webpage
cd exercise-webpage/
