#!/bin/bash

fail_olemas() {
    [ -f "$1" ]
}

if fail_olemas "/etc/passwd"; then
    echo "Fail on olemas."
else
    echo "Faili ei leitud."
fi
