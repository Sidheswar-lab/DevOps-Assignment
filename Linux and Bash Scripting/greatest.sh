#!/bin/bash
echo "Enter first number:"
read a
echo "Enter second number:"
read b
echo "Enter thrid number"
read c
echo "a = $a, b = $b, c = $c"
if (( a > b ))
then
	if [ "$a" -gt "$c" ]
	then
		echo "Greatest a = $a"
	else
		echo "Greatest c = $c"
	fi
else
	if [[ $b -gt $c ]]
	then
		echo "Greatest b = $b"
	else
		echo "Greatest c = $c"
	fi
fi
