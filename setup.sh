#!/bin/bash
sudo apt-get install git subversion zip unzip flex bison -y
curl -s "https://get.sdkman.io" | bash
source "/home/vagrant/.sdkman/bin/sdkman-init.sh"
sdk install java $(sdk list java | grep -o "8\.[0-9]*\.[0-9]*\.hs-adpt" | head -1)
sdk install sbt
mkdir -p dumpconf models
cd kconfigreader
sbt mkrun