# RAK833-LoRaGateway-RPi

based on the latest SX1301 driver [lora_gateway](https://github.com/Lora-net/lora_gateway) v5.0.1 and semtech [packet_forwarder](https://github.com/Lora-net/packet_forwarder) v4.0.1  


##	Installation procedure

step1 : Download and install [Raspbian Stretch LITE](https://www.raspberrypi.org/downloads/raspbian/) 


step2 : Clone the installer and start the installation

      $ git clone https://github.com/RAKWireless/RAK833-LoRaGateway-RPi.git ~/rak833-loragateway
      $ cd ~/rak833-loragateway
      $ sudo ./install.sh

step3 : Now you have a running gateway after restart! in additon you can check the log info at /var/log/syslog.
