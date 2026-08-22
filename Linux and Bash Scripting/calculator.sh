#!/bin/bash
echo "Enter first number"
read a
echo "Enter second number"
read b
c=$((a + b))
echo $c
echo "a = $a, b = $b"
echo "Sum = `expr $a + $b`"
echo "Difference = $((b - a))"
echo "Difference = $((b - a))"
echo "Multiplication = $((b * a))"
echo "Division = $((b / a))"
echo "Modulus = $((b % a))"
echo "Equality = $((b == a))"
echo "Not Equal = $((a != b))";
