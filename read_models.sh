#!/bin/bash
cd
mkdir -p /vagrant/data
rm -f /vagrant/data/log.txt

BINDING_ENUMS=(S_UNKNOWN S_BOOLEAN S_TRISTATE S_INT S_HEX S_STRING S_OTHER P_UNKNOWN P_PROMPT P_COMMENT P_MENU P_DEFAULT P_CHOICE P_SELECT P_RANGE P_ENV P_SYMBOL E_SYMBOL E_NOT E_EQUAL E_UNEQUAL E_OR E_AND E_LIST E_RANGE E_CHOICE P_IMPLY E_NONE E_LTH E_LEQ E_GTH E_GEQ dir_dep)
TAGS_KCONFIGREADER="rsf|dimacs|features|model|kconfigreader|tseytin"
TAGS_KMAX="kclause|kmax"

git-clone() {
    if [[ ! -d "$1" ]]; then
        echo Cloning $2 to $1 ...
        git clone $2 $1
    fi
}

# compiles the C program that extracts Kconfig constraints from Kconfig files
# for kconfigreader and kmax, this compiles dumpconf and kextractor against the Kconfig parser, respectively
c-binding() (
    if [ $2 = buildroot ]; then
        find ./ -type f -name "*Config.in" -exec sed -i 's/source "\$.*//g' {} \; # ignore generated Kconfig files in buildroot
    fi
    set -e
    mkdir -p /vagrant/data/c-bindings/$2
    args=""
    binding_files=$(echo $4 | tr , ' ')
    binding_dir=$(dirname $binding_files | head -n1)
    for enum in ${BINDING_ENUMS[@]}; do
        if grep -qrnw $binding_dir -e $enum; then
            args="$args -DENUM_$enum"
        fi
    done
    if ! echo $4 | grep -q c-bindings; then
        # make sure all dependencies for the C program are compiled
        # make config sometimes asks for integers (not easily simulated with "yes"), which is why we add a timeout
        make $binding_files >/dev/null || (yes | make allyesconfig >/dev/null) || (yes "" | timeout 20s make config > /dev/null) || true
        strip -N main $binding_dir/*.o || true
        gcc /vagrant/$1.c $binding_files -I $binding_dir -Wall -Werror=switch $args -Wno-format -o /vagrant/data/c-bindings/$2/$3.$1
        echo /vagrant/data/c-bindings/$2/$3.$1
    else
        echo $4
    fi
)

kconfigreader() (
    set -e
    mkdir -p /vagrant/data/models/$1
    writeDimacs=--writeDimacs
    if [ $1 = freetz-ng ]; then
        touch make/Config.in.generated make/external.in.generated config/custom.in # ugly hack because freetz-ng is weird
        writeDimacs="" # Tseytin transformation crashes for freetz-ng
    fi
    /vagrant/kconfigreader/run.sh de.fosd.typechef.kconfig.KConfigReader --fast --dumpconf $3 $writeDimacs $4 /vagrant/data/models/$1/$2
    echo $1,$2,$3,$4,$5 >> /vagrant/data/models.txt
)

git-run() (
    set -e
    echo >> /vagrant/data/log.txt
    if [[ ! -f "/vagrant/data/models/$1/$2.model" ]]; then
        echo -n "Reading feature model for $1 at tag $2 ..." >> /vagrant/data/log.txt
        cd $1
        git reset --hard
        git clean -fx >/dev/null
        git checkout -f $2
        kconfigreader $1 $2 $(c-binding dumpconf $1 $2 $3) $4 $5
        cd
        echo -n " done." >> /vagrant/data/log.txt
    else
        echo -n "Skipping feature model for $1 at tag $2" >> /vagrant/data/log.txt
    fi
)

svn-run() (
    set -e
    echo >> /vagrant/data/log.txt
    if [[ ! -f "/vagrant/data/models/$1/$3.model" ]]; then
        echo -n "Reading feature model for $1 at tag $3 ..." >> /vagrant/data/log.txt
        rm -rf $1
        svn checkout $2 $1
        cd $1
        kconfigreader $1 $3 $(dumpconf $1 $3 $4) $5 $6
        cd
        echo -n " done." >> /vagrant/data/log.txt
    else
        echo -n "Skipping feature model for $1 at tag $3" >> /vagrant/data/log.txt
    fi
)

# More information on the systems below can be found in Berger et al.'s "Variability Modeling in the Systems Software Domain".
# Our general strategy is to read feature models for all tags (provided that tags give a meaningful history).
# We usually compile dumpconf against the project source to get the most accurate translation.
# Sometimes this is not possible, then we use dumpconf compiled for a Linux version with a similar Kconfig dialect (in most projects, the Kconfig parser is cloned&owned from Linux).
# You can also read feature models for any other tags/commits (e.g., for every commit that changes a Kconfig file), although usually very old versions won't work (because Kconfig might have only been introduced later) and very recent versions might also not work (because they use new/esoteric Kconfig features not supported by kconfigreader or dumpconf).

# # Linux
# git-clone linux https://github.com/torvalds/linux
# for tag in $(git -C linux tag | grep -v rc | grep -v tree); do
#     if git -C ~/linux ls-tree -r $tag --name-only | grep -q arch/i386; then
#         git-run linux $tag scripts/kconfig/zconf.tab.o arch/i386/Kconfig $TAGS # in old versions, x86 is called i386
#     else
#         git-run linux $tag scripts/kconfig/zconf.tab.o arch/x86/Kconfig $TAGS
#     fi
# done

git-clone linux https://github.com/torvalds/linux
#git-run linux v5.0 scripts/kconfig/*.o arch/x86/Kconfig $TAGS
cd ~/linux

for tag in $(git tag | grep -v rc | grep -v tree); do
    git reset --hard
    git clean -fx
    git checkout -f $tag
    c-binding kextractor linux $tag scripts/kconfig/*.o
done

# # axTLS
# for tag in $(cd axtls; svn ls ^/tags); do
#     svn-run axtls svn://svn.code.sf.net/p/axtls/code/tags/$(echo $tag | tr / ' ') $(echo $tag | tr / ' ') config/scripts/config config/Config.in $TAGS
# done

# # Buildroot
# git-clone buildroot https://github.com/buildroot/buildroot
# git-run linux v4.17 scripts/kconfig/zconf.tab.o arch/x86/Kconfig $TAGS
# for tag in $(git -C buildroot tag | grep -v rc | grep -v -e '\..*\.'); do
#     git-run buildroot $tag /vagrant/data/c-bindings/linux/v4.17.dumpconf Config.in $TAGS
# done

# # BusyBox
# git-clone busybox https://github.com/mirror/busybox
# for tag in $(git -C busybox tag | grep -v pre | grep -v alpha | grep -v rc); do
#     git-run busybox $tag scripts/kconfig/zconf.tab.o Config.in $TAGS
# done

# # https://github.com/coreboot/coreboot uses a modified Kconfig with wildcards for the source directive

# # EmbToolkit
# git-clone embtoolkit https://github.com/ndmsystems/embtoolkit
# for tag in $(git -C embtoolkit tag | grep -v rc | grep -v -e '-.*-'); do
#     git-run embtoolkit $tag scripts/kconfig/zconf.tab.o Kconfig $TAGS
# done

# # Fiasco
# git-clone fiasco https://github.com/kernkonzept/fiasco
# git-run linux v5.0 scripts/kconfig/*.o arch/x86/Kconfig $TAGS
# git-run fiasco d393c79a5f67bb5466fa69b061ede0f81b6398db /vagrant/data/c-bindings/linux/v5.0.dumpconf src/Kconfig $TAGS

# # https://github.com/Freetz/freetz uses Kconfig, but cannot be parsed with dumpconf, so we use freetz-ng instead (which is newer anyway)

# # Freetz-NG
# git-clone freetz-ng https://github.com/Freetz-NG/freetz-ng
# git-run linux v5.0 scripts/kconfig/*.o arch/x86/Kconfig $TAGS
# git-run freetz-ng 88b972a6283bfd65ae1bbf559e53caf7bb661ae3 /vagrant/data/c-bindings/linux/v5.0.dumpconf config/Config.in "rsf|features|model|kconfigreader"

# # Toybox
# git-clone toybox https://github.com/landley/toybox
# as a workaround, use dumpconf from Linux, because it cannot be built in this repository
# git-run linux v2.6.12 scripts/kconfig/zconf.tab.o arch/x86/Kconfig $TAGS
# for tag in $(git -C toybox tag); do
#     git-run toybox $tag /vagrant/data/c-bindings/linux/v2.6.12.dumpconf Config.in $TAGS
# done

# # uClibc-ng
# git-clone uclibc-ng https://github.com/wbx-github/uclibc-ng
# for tag in $(git -C uclibc-ng tag); do
#     git-run uclibc-ng $tag extra/config/zconf.tab.o extra/Configs/Config.in $TAGS
# done

# # https://github.com/rhuitl/uClinux is not so easy to set up, because it depends on vendor files

# # https://github.com/zephyrproject-rtos/zephyr also uses Kconfig, but a modified dialect based on Kconfiglib, which is not compatible with kconfigreader