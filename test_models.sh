#!/bin/bash
if [ $# -ne 1 ]; then
    echo "Usage: test_models.sh <reader>"
    exit 1
fi
READER=$1
if [ ! $READER = kconfigreader ] && [ ! $READER = kmax ]; then
    echo "invalid reader"
    exit 1
fi

cd /vagrant/data/models
echo system,tag,features,variables,clauses
for system in *; do
    cd $system
    for file in *.model; do
        tag=$(basename $file .$READER.model)
        if ([ ! -f $tag.$READER.features ] || [ ! -f $tag.$READER.model ] || [ ! -f $tag.$READER.dimacs ]) ||
            ([ $READER = kconfigreader ] && [ ! -f $tag.$READER.rsf ]) ||
            ([ $READER = kmax ] && [ ! -f $tag.$READER.kclause ]); then
            echo some files are missing for $system at $tag
            exit 1
        fi
        features=$(wc -l $tag.$READER.features | cut -d' ' -f1)
        variables=$(cat $tag.$READER.dimacs | grep -E ^p | cut -d' ' -f3)
        clauses=$(cat $tag.$READER.dimacs | grep -E ^p | cut -d' ' -f4)
        echo $system,$tag,$features,$variables,$clauses
    done
    cd ..
done