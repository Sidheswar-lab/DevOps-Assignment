#!/bin/bash 

echo "Enter first number:" 

read a 

echo "Enter second number:" 

read b 

(( a > b )) && echo "Greatest a = $a" || echo "Greatest $b" 
