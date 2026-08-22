#!/bin/bash

echo "Available Network Interfaces and IP Addresses"

ip addr | awk '
/^[0-9]+: / {
    interface=$2
    sub(":", "", interface)
}

/inet / {
    print interface " -> " $2
}
'
