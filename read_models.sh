#!/bin/bash
if [ $# -ne 1 ]; then
    echo "Usage: read_models.sh <reader>"
    exit 1
fi
READER=$1
LOG=/vagrant/data/log_$READER.txt
if [ $READER = kconfigreader ]; then
    BINDING=dumpconf
    TAGS="kconfigreader|rsf|features|model|dimacs|cnf|tseytin"
elif [ $READER = kmax ]; then
    BINDING=kextractor
    TAGS="kmax|kclause|features|model|dimacs|cnf|tseytin"
else
    echo "invalid reader"
    exit 1
fi
BINDING_ENUMS=(S_UNKNOWN S_BOOLEAN S_TRISTATE S_INT S_HEX S_STRING S_OTHER P_UNKNOWN P_PROMPT P_COMMENT P_MENU P_DEFAULT P_CHOICE P_SELECT P_RANGE P_ENV P_SYMBOL E_SYMBOL E_NOT E_EQUAL E_UNEQUAL E_OR E_AND E_LIST E_RANGE E_CHOICE P_IMPLY E_NONE E_LTH E_LEQ E_GTH E_GEQ dir_dep)

cd
mkdir -p /vagrant/data
echo -n > $LOG

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
        make $binding_files >/dev/null || (yes | make allyesconfig >/dev/null) || (yes | make xconfig >/dev/null) || (yes "" | timeout 20s make config >/dev/null) || true
        strip -N main $binding_dir/*.o || true
        cmd="gcc /vagrant/$1.c $binding_files -I $binding_dir -Wall -Werror=switch $args -Wno-format -o /vagrant/data/c-bindings/$2/$3.$1"
        (echo $cmd >> $LOG) && eval $cmd
        echo /vagrant/data/c-bindings/$2/$3.$1
    else
        echo $4
    fi
)

read-model() (
    # read-model kconfigreader|kmax system commit c-binding Kconfig tags env
    set -e
    mkdir -p /vagrant/data/models/$2
    writeDimacs=--writeDimacs
    if [ -z "$7" ]; then
        env=""
    else
        env="$(echo '' -e $7 | sed 's/,/ -e /g')"
    fi
    if [ $2 = freetz-ng ]; then
        touch make/Config.in.generated make/external.in.generated config/custom.in # ugly hack because freetz-ng is weird
        writeDimacs="" # Tseytin transformation crashes for freetz-ng
    fi
    if [ $2 = linux ]; then
        # ignore all constraints that use the newer $(success,...) syntax
        find ./ -type f -name "*Kconfig*" -exec sed -i 's/\s*default $(.*//g' {} \;
        find ./ -type f -name "*Kconfig*" -exec sed -i 's/\s*depends on $(.*//g' {} \;
        find ./ -type f -name "*Kconfig*" -exec sed -i 's/\s*def_bool $(.*//g' {} \;
    fi
    if [ $1 = kconfigreader ]; then
        cmd="~/kconfigreader/run.sh de.fosd.typechef.kconfig.KConfigReader --fast --dumpconf $4 $writeDimacs $5 /vagrant/data/models/$2/$3.$1"
        (echo $cmd | tee -a $LOG) && eval $cmd
    elif [ $1 = kmax ]; then
        cmd="$4 --extract -o /vagrant/data/models/$2/$3.$1.kclause $env $5"
        (echo $cmd | tee -a $LOG) && eval $cmd
        cmd="$4 --configs $env $5 > /vagrant/data/models/$2/$3.$1.features"
        (echo $cmd | tee -a $LOG) && eval $cmd
        cmd="kclause < /vagrant/data/models/$2/$3.$1.kclause > /vagrant/data/models/$2/$3.$1.model"
        (echo $cmd | tee -a $LOG) && eval $cmd
        cmd="python3 /vagrant/kclause2dimacs.py /vagrant/data/models/$2/$3.$1.model > /vagrant/data/models/$2/$3.$1.dimacs"
        (echo $cmd | tee -a $LOG) && eval $cmd
    fi
    echo $2,$3,$4,$5,$6 >> /vagrant/data/models.txt
)

git-checkout() (
    if [[ ! -d "$1" ]]; then
        echo "Cloning $1" | tee -a $LOG
        git clone $2 $1
    fi
    if [ ! -z "$3" ]; then
        cd $1
        git reset --hard
        git clean -fx
        git checkout -f $3
    fi
)

svn-checkout() (
    rm -rf $1
    svn checkout $2 $1
)

run() (
    set -e
    echo | tee -a $LOG
    if [[ ! -f "/vagrant/data/models/$1/$3.$READER.model" ]]; then
        trap 'ec=$?; (( ec != 0 )) && (rm -f /vagrant/data/models/'$1'/'$3'.'$READER'* && echo FAIL | tee -a $LOG) || (echo SUCCESS | tee -a $LOG)' EXIT
        echo "Checking out $3 in $1" | tee -a $LOG
        if [[ $2 == svn* ]]; then
            vcs=svn-checkout
            else
            vcs=git-checkout
        fi
        eval $vcs $1 $2 $3
        cd $1
        echo "Compiling C binding $BINDING for $1 at $3" | tee -a $LOG
        binding_path=$(c-binding $BINDING $1 $3 $4)
        echo "Reading feature model for $1 at $3" | tee -a $LOG
        read-model $READER $1 $3 $binding_path $5 $6 $7
        cd
    else
        echo "Skipping feature model for $1 at $3" | tee -a $LOG
    fi
)

# More information on the systems below can be found in Berger et al.'s "Variability Modeling in the Systems Software Domain".
# Our general strategy is to read feature models for all tags (provided that tags give a meaningful history).
# We usually compile dumpconf against the project source to get the most accurate translation.
# Sometimes this is not possible, then we use dumpconf compiled for a Linux version with a similar Kconfig dialect (in most projects, the Kconfig parser is cloned&owned from Linux).
# You can also read feature models for any other tags/commits (e.g., for every commit that changes a Kconfig file), although usually very old versions won't work (because Kconfig might have only been introduced later) and very recent versions might also not work (because they use new/esoteric Kconfig features not supported by kconfigreader or dumpconf).

# Linux
git-checkout linux https://github.com/torvalds/linux
linux_env="ARCH=x86,SRCARCH=x86,KERNELVERSION=kcu,srctree=./,CC=cc,LD=ld,RUSTC=rustc"
for tag in $(git -C linux tag | grep -v rc | grep -v tree | grep -v v2.6.11); do
    if git -C linux ls-tree -r $tag --name-only | grep -q arch/i386; then
        run linux https://github.com/torvalds/linux $tag scripts/kconfig/*.o arch/i386/Kconfig $TAGS $linux_env # in old versions, x86 is called i386
    else
        run linux https://github.com/torvalds/linux $tag scripts/kconfig/*.o arch/x86/Kconfig $TAGS $linux_env
    fi
done

# axTLS
svn-checkout axtls svn://svn.code.sf.net/p/axtls/code/trunk
for tag in $(cd axtls; svn ls ^/tags); do
    run axtls svn://svn.code.sf.net/p/axtls/code/tags/$(echo $tag | tr / ' ') $(echo $tag | tr / ' ') config/scripts/config/*.o config/Config.in $TAGS
done

# Buildroot
run linux https://github.com/torvalds/linux v4.17 scripts/kconfig/*.o arch/x86/Kconfig $TAGS $linux_env
git-checkout buildroot https://github.com/buildroot/buildroot
for tag in $(git -C buildroot tag | grep -v rc | grep -v -e '\..*\.'); do
    run buildroot https://github.com/buildroot/buildroot $tag /vagrant/data/c-bindings/linux/v4.17.$BINDING Config.in $TAGS
done

# BusyBox
git-checkout busybox https://github.com/mirror/busybox
for tag in $(git -C busybox tag | grep -v pre | grep -v alpha | grep -v rc); do
    run busybox https://github.com/mirror/busybox $tag scripts/kconfig/*.o Config.in $TAGS
done

# https://github.com/coreboot/coreboot uses a modified Kconfig with wildcards for the source directive

# EmbToolkit
git-checkout embtoolkit https://github.com/ndmsystems/embtoolkit
for tag in $(git -C embtoolkit tag | grep -v rc | grep -v -e '-.*-'); do
    run embtoolkit https://github.com/ndmsystems/embtoolkit $tag scripts/kconfig/*.o Kconfig $TAGS
done

# # Fiasco
# run linux https://github.com/torvalds/linux v5.0 scripts/kconfig/*.o arch/x86/Kconfig $TAGS $linux_env
# run fiasco https://github.com/kernkonzept/fiasco d393c79a5f67bb5466fa69b061ede0f81b6398db /vagrant/data/c-bindings/linux/v5.0.$BINDING src/Kconfig $TAGS

# # https://github.com/Freetz/freetz uses Kconfig, but cannot be parsed with dumpconf, so we use freetz-ng instead (which is newer anyway)

# # Freetz-NG
# run linux https://github.com/torvalds/linux v5.0 scripts/kconfig/*.o arch/x86/Kconfig $TAGS $linux_env
# run freetz-ng https://github.com/Freetz-NG/freetz-ng 88b972a6283bfd65ae1bbf559e53caf7bb661ae3 /vagrant/data/c-bindings/linux/v5.0.$BINDING config/Config.in "rsf|features|model|kconfigreader"

# # Toybox
# as a workaround, use dumpconf from Linux, because it cannot be built in this repository
# run linux https://github.com/torvalds/linux v2.6.12 scripts/kconfig/*.o arch/i386/Kconfig $TAGS $linux_env
# git-checkout toybox https://github.com/landley/toybox
# for tag in $(git -C toybox tag); do
#     run toybox https://github.com/landley/toybox $tag /vagrant/data/c-bindings/linux/v2.6.12.$BINDING Config.in $TAGS
# done

# # uClibc-ng
# git-checkout uclibc-ng https://github.com/wbx-github/uclibc-ng
# for tag in $(git -C uclibc-ng tag); do
#     run uclibc-ng https://github.com/wbx-github/uclibc-ng $tag extra/config/zconf.tab.o extra/Configs/Config.in $TAGS
# done

# # https://github.com/rhuitl/uClinux is not so easy to set up, because it depends on vendor files

# # https://github.com/zephyrproject-rtos/zephyr also uses Kconfig, but a modified dialect based on Kconfiglib, which is not compatible with kconfigreader