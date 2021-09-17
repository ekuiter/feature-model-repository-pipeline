#!/bin/bash
cd
rm -f /vagrant/log.txt

DUMPCONF_ENUMS=(S_UNKNOWN S_BOOLEAN S_TRISTATE S_INT S_HEX S_STRING S_OTHER P_UNKNOWN P_PROMPT P_COMMENT P_MENU P_DEFAULT P_CHOICE P_SELECT P_RANGE P_ENV P_SYMBOL E_SYMBOL E_NOT E_EQUAL E_UNEQUAL E_OR E_AND E_LIST E_RANGE E_CHOICE P_IMPLY E_NONE E_LTH E_LEQ E_GTH E_GEQ)

git-clone() {
    if [[ ! -d "$1" ]]; then
        echo Cloning $2 to $1 ...
        git clone $2 $1
    fi
}

svn-clone() {
    if [[ ! -d "$1" ]]; then
        echo Cloning $2 to $1 ...
        svn checkout $2 $1
    fi
}

kconfigreader() (
    set -e
    mkdir -p /vagrant/models/$1
    #find ./ -type f -name "*Kconfig*" -exec sed -i 's/\tdefault \$.*//g' {} \; # helps to read newer Linux versions
    make allyesconfig >/dev/null
    args=""
    for enum in ${DUMPCONF_ENUMS[@]}; do
        if grep -qrnw $4 -e $enum; then
            args="$args -DENUM_$enum"
        fi
    done
    gcc /vagrant/dumpconf.c $5 -I $4 -Wall -Werror=switch $args -Wno-format -o /vagrant/dumpconf/$1-$2
    /vagrant/kconfigreader/run.sh de.fosd.typechef.kconfig.KConfigReader --fast --dumpconf /vagrant/dumpconf/$1-$2 --writeDimacs $3 /vagrant/models/$1/$2
    echo $1,$2,$3,$6 >> /vagrant/models/models.txt
)

git-run() (
    set -e
    echo >> /vagrant/log.txt
    if [[ ! -f "/vagrant/models/$1/$2.model" ]]; then
        echo -n "Reading feature model for $1 at commit $2 ..." >> /vagrant/log.txt
        cd $1
        git reset --hard
        git clean -fx
        git checkout -f $2
        kconfigreader $1 $2 $3 $4 $5 $6
        cd
        echo -n " done." >> /vagrant/log.txt
    else
        echo -n "Skipping feature model for $1 at commit $2" >> /vagrant/log.txt
    fi
)

svn-run() (
    set -e
    echo >> /vagrant/log.txt
    if [[ ! -f "/vagrant/models/$1/$2.model" ]]; then
        echo -n "Reading feature model for $1 at commit $2 ..." >> /vagrant/log.txt
        cd $1
        svn switch $(svn info | grep "Repository Root" | cut -d: -f2-)/$2 --ignore-ancestry
        kconfigreader $1 $2 $3 $4 $5 $6
        cd
        echo -n " done." >> /vagrant/log.txt
    else
        echo -n "Skipping feature model for $1 at commit $2" >> /vagrant/log.txt
    fi
)

# more information on systems in Berger et al.'s "Variability Modeling in the Systems Software Domain"
git-clone linux https://github.com/torvalds/linux
git-clone busybox https://github.com/mirror/busybox
svn-clone axtls svn://svn.code.sf.net/p/axtls/code/trunk

# for tag in $(git -C linux tag | grep -v rc | grep -v tree); do
#     if git -C ~/linux ls-tree -r $tag --name-only | grep -q arch/i386; then
#         git-run linux $tag arch/i386/Kconfig scripts/kconfig scripts/kconfig/zconf.tab.o # in older Linux versions, x86 is i386
#     else
#         git-run linux $tag arch/x86/Kconfig scripts/kconfig scripts/kconfig/zconf.tab.o
#     fi
# done

for tag in $(git -C busybox tag | grep -v pre | grep -v alpha | grep -v rc); do
    git-run busybox $tag Config.in scripts/kconfig scripts/kconfig/zconf.tab.o "rsf|dimacs|features|model|kconfigreader|tseytin"
done

#svn-run axtls tags/release-1.0.0 config/Config.in config/scripts/config/zconf.tab.o

# make allyesconfig?