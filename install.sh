#!/bin/bash

# Stop on the first sign of trouble
set -e

if [ $UID != 0 ]; then
    echo "ERROR: Operation not permitted. Forgot sudo?"
    exit 1
fi

SCRIPT_DIR=$(pwd)

pushd lora
./install.sh
popd

pushd loraserver
./install.sh
popd

pushd ap
./install.sh
popd

echo "Please reboot your system."
sleep 3
#shutdown -r now
