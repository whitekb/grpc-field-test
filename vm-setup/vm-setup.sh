#!/bin/bash

# get the system up-to-date
sudo apt update

# install docker
./get-docker.sh

# install certbot (Google ESP uses NGINX)
sudo apt install certbot python-certbot-nginx -y

# upgrade all system components
sudo apt upgrade -y
