#!/bin/bash
sudo apt-get update
sudo apt-get install git subversion python3-setuptools python3-dev flex bison bc libssl-dev libelf-dev -y --force-yes
cd /vagrant
git clone https://github.com/paulgazz/kmax.git
cd kmax
git checkout c6e83a07d4f916267cb9e718c0b2de42ecfe4147
sudo python3 setup.py install