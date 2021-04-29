#!/bin/bash

yum -y update

# install Docker
yum -y install docker

# install demo app
docker run --name f5demo -p 80:80 -p 443:443 -d f5devcentral/f5-demo-app:latest
