#!/bin/bash
set -e
echo Reading feature model for linux-$1-$2 ...
cd ~/kconfigreader
git clone https://github.com/torvalds/linux >/dev/null 2>&1 || true
cd linux
git reset --hard >/dev/null 2>&1
git checkout $1 >/dev/null 2>&1
make allyesconfig >/dev/null 2>&1
gcc ../kconfigreader/dumpconf/dumpconf.c scripts/kconfig/zconf.tab.o -I scripts/kconfig/ -Wall -o /vagrant/dumpconf/linux-$1 >/dev/null 2>&1
../kconfigreader/run.sh de.fosd.typechef.kconfig.KConfigReader --dumpconf /vagrant/dumpconf/linux-$1 --writeDimacs arch/$2/Kconfig /vagrant/model/linux-$1-$2
cd ~/kconfigreader