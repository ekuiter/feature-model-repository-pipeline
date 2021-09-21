#!/bin/bash
echo "deb https://repo.scala-sbt.org/scalasbt/debian all main" | sudo tee /etc/apt/sources.list.d/sbt.list
echo "deb https://repo.scala-sbt.org/scalasbt/debian /" | sudo tee /etc/apt/sources.list.d/sbt_old.list
curl -sL "https://keyserver.ubuntu.com/pks/lookup?op=get&search=0x2EE0EA64E40A89B84B2DF73499E82A75642AC823" | sudo apt-key add
sudo apt-get update
sudo apt-get install git subversion openjdk-7-jdk sbt=0.13.6 gcc g++ flex bison -y --force-yes # tested versions of Java and Scala build tool
cd /vagrant
mkdir -p dumpconf models
sudo git clone https://github.com/ckaestne/kconfigreader.git
cd kconfigreader
git checkout 913bf3178af5a8ac8bedc5e8733561ed38280cf9 # tested version of Kconfigreader
sbt mkrun