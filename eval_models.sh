#!/bin/bash
if [ $# -ne 1 ]; then
    echo "Usage: eval_models.sh <reader>"
    exit 1
fi
READER=$1
CSV=/vagrant/data/eval_$READER.csv
if [ ! $READER = kconfigreader ] && [ ! $READER = kmax ]; then
    echo "invalid reader"
    exit 1
fi
echo -n > $CSV

cd /vagrant/data/models
echo system,tag,features,variables,clauses | tee -a $CSV
for system in *; do
    cd $system
    for file in $(ls *.$READER.model 2>/dev/null); do
        tag=$(basename $file .$READER.model)
        if ([ ! -f $tag.$READER.features ] || [ ! -f $tag.$READER.model ] || [ ! -f $tag.$READER.dimacs ]) ||
            ([ $READER = kconfigreader ] && [ ! -f $tag.$READER.rsf ]) ||
            ([ $READER = kmax ] && [ ! -f $tag.$READER.kclause ]); then
            echo "WARNING: some files are missing for $system at $tag"
        fi
        if [ -f $tag.$READER.dimacs ]; then
            /vagrant/MiniSat_v1.14_linux $tag.$READER.dimacs > /dev/null
            if [ $? -ne 10 ]; then
                echo "WARNING: DIMACS for $system at $tag is unsatisfiable"
            fi
        fi
        features=$(wc -l $tag.$READER.features | cut -d' ' -f1)
        variables=$(cat $tag.$READER.dimacs 2>/dev/null | grep -E ^p | cut -d' ' -f3)
        clauses=$(cat $tag.$READER.dimacs 2>/dev/null | grep -E ^p | cut -d' ' -f4)
        echo $system,$tag,$features,$variables,$clauses | tee -a $CSV
    done
    cd ..
done