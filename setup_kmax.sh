#!/bin/bash
set -e
sudo apt-get update
sudo apt-get install git subversion python3-setuptools python3-dev flex bison bc libssl-dev libelf-dev -y --force-yes # python3-pip
#pip3 install z3
mkdir -p /vagrant/data
cd
git clone https://github.com/paulgazz/kmax.git || true
cd kmax
git checkout c6e83a07d4f916267cb9e718c0b2de42ecfe4147 # tested version of Kmax
sudo python3 setup.py install