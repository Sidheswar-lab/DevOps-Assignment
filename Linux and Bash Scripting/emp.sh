#!/bin/bash

echo "Employees with salary greater than 70000"
awk -F',' 'NR > 1 && $4 > 70000 {print $0}' employee.txt

echo
echo "Employee name and salary after 10% increment"
awk -F',' 'NR > 1 {
    new_salary = $4 * 1.10
    printf "%s %.2f\n", $1, new_salary
}' employee.txt

echo
echo "Total employees and average salary"
awk -F',' 'NR > 1 {
    total += $4
    count++
}
END {
    printf "Total Employees: %d\n", count
    printf "Average Salary: %.2f\n", total/count
}' employee.txt

echo
echo "After deleting third employee's record"
sed '4d' employee.txt

echo
echo "Commas replaced by pipes"
sed 's/,/|/g' employee.txt

echo
echo "After deleting lines containing 'sales'"
sed '/sales/Id' employee.txt
