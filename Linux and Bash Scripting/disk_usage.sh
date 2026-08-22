#!/bin/bash

usage=$(df / | awk 'NR==2 {print $5}' | tr -d '%')

if test "$usage" -gt 80
then
    echo "Critical"
else
    echo "Normal"
fi
