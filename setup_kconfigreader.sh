#!/bin/bash
set -e
chmod +x /vagrant/*.sh
chmod +x /vagrant/MiniSat_v1.14_linux
echo "deb https://repo.scala-sbt.org/scalasbt/debian all main" | sudo tee /etc/apt/sources.list.d/sbt.list
echo "deb https://repo.scala-sbt.org/scalasbt/debian /" | sudo tee /etc/apt/sources.list.d/sbt_old.list
sudo apt-get update
sudo apt-get install git subversion openjdk-7-jdk sbt=0.13.6 gcc g++ flex bison -y --force-yes # tested versions of Java and Scala build tool
cd
git clone https://github.com/ckaestne/kconfigreader.git || true
cd kconfigreader
git checkout 913bf3178af5a8ac8bedc5e8733561ed38280cf9 # tested version of Kconfigreader
sbt mkrun
cd
gcc -o eval_writedimacs /vagrant/eval_writedimacs.c