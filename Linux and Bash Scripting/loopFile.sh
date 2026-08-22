#!/bin/bash

empty=0
short=0
long=0

for file in *.sh
do
    line=$(cat "$file" | wc -l)

    if [ $line -eq 0 ]
    then
        echo "$file : File is empty"
        ((empty++))

    elif [ $line -le 5 ]
    then
        echo "$file : Short file ($line lines)"
        ((short++))

    else
        echo "$file : Long file ($line lines)"
        ((long++))
    fi

done

echo "Summary:"
echo "Empty Files : $empty"
echo "Short Files : $short"
echo "Long Files : $long"
