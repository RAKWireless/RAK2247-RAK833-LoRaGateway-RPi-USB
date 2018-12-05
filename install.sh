#!/bin/bash

# Stop on the first sign of trouble
set -e

if [ $UID != 0 ]; then
    echo "ERROR: Operation not permitted. Forgot sudo?"
    exit 1
fi

SCRIPT_DIR=$(pwd)

VERSION="master"
if [[ $1 != "" ]]; then VERSION=$1; fi

echo "The Things Network Gateway installer"
echo "Version $VERSION"

# Request gateway configuration data
# There are two ways to do it, manually specify everything
# or rely on the gateway EUI and retrieve settings files from remote (recommended)
echo "Gateway configuration:"

# Try to get gateway ID from MAC address
# First try eth0, if that does not exist, try wlan0 (for RPi Zero)
GATEWAY_EUI_NIC="eth0"
if [[ `grep "$GATEWAY_EUI_NIC" /proc/net/dev` == "" ]]; then
    GATEWAY_EUI_NIC="wlan0"
fi

if [[ `grep "$GATEWAY_EUI_NIC" /proc/net/dev` == "" ]]; then
    echo "ERROR: No network interface found. Cannot set gateway ID."
    exit 1
fi

GATEWAY_EUI=$(ip link show $GATEWAY_EUI_NIC | awk '/ether/ {print $2}' | awk -F\: '{print $1$2$3"FFFE"$4$5$6}')
GATEWAY_EUI=${GATEWAY_EUI^^} # toupper

echo "Detected EUI $GATEWAY_EUI from $GATEWAY_EUI_NIC"

# Check dependencies
echo "Installing dependencies..."
apt-get -y install git libftdi-dev libusb-dev

# Build libraries

git clone https://github.com/devttys0/libmpsse.git
pushd libmpsse/src
./configure --disable-python
make
make install
ldconfig
popd

# Install LoRaWAN packet forwarder repositories
INSTALL_DIR="/opt/ttn-gateway"
if [ ! -d "$INSTALL_DIR" ]; then mkdir $INSTALL_DIR; fi
pushd $INSTALL_DIR

# Build LoRa gateway app

git clone https://github.com/Lora-net/lora_gateway.git

pushd lora_gateway

cp ./libloragw/99-libftdi.rules /etc/udev/rules.d/99-libftdi.rules
cp $SCRIPT_DIR/loragw_spi.ftdi.c ./libloragw/src/
cp $SCRIPT_DIR/Makefile-gw-lib ./libloragw/Makefile
cp $SCRIPT_DIR/Makefile-lbt-test ./util_lbt_test/Makefile
cp $SCRIPT_DIR/Makefile-pkt-logger ./util_pkt_logger/Makefile
cp $SCRIPT_DIR/Makefile-spectral-scan ./util_spectral_scan/Makefile
cp $SCRIPT_DIR/Makefile-spi-stress ./util_spi_stress/Makefile
cp $SCRIPT_DIR/Makefile-tx-continuous ./util_tx_continuous/Makefile
cp $SCRIPT_DIR/Makefile-tx-test ./util_tx_test/Makefile
cp $SCRIPT_DIR/library.cfg ./libloragw/
cp $SCRIPT_DIR/Makefile-gw ./Makefile

sed -i -e 's/CFG_SPI= native/CFG_SPI= ftdi/g' ./libloragw/library.cfg

make
popd

# Build packet forwarder

git clone https://github.com/Lora-net/packet_forwarder.git
pushd packet_forwarder

cp $SCRIPT_DIR/Makefile-pk ./lora_pkt_fwd/Makefile

make

popd


LOCAL_CONFIG_FILE=$INSTALL_DIR/packet_forwarder/lora_pkt_fwd/local_conf.json

#config local_conf.json

    echo -e "{\n\t\"gateway_conf\": {\n\t\t\"gateway_ID\": \"$GATEWAY_EUI\",\n\t\t\"server_address\": \"router.eu.thethings.network\",\n\t\t\"serv_port_up\": 1700,\n\t\t\"serv_port_down\": 1700,\n\t\t\"serv_enabled\": true,\n\t\t\"ref_latitude\": 0,\n\t\t\"ref_longitude\": 0,\n\t\t\"ref_altitude\": 0 \n\t}\n}" >$LOCAL_CONFIG_FILE

echo "Gateway EUI is: $GATEWAY_EUI"
echo "The hostname is: $NEW_HOSTNAME"
echo "Open TTN console and register your gateway using your EUI: https://console.thethingsnetwork.org/gateways"
echo
echo "Installation completed."

# Start packet forwarder as a service
#cp ./start.sh $INSTALL_DIR/bin/
cp $SCRIPT_DIR/ttn-gateway.service /lib/systemd/system/
systemctl enable ttn-gateway.service

echo "The system will reboot in 5 seconds..."
sleep 5
shutdown -r now

