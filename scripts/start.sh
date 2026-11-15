#!/bin/bash
cd /home/ubuntu/minecraft-server
screen -dmS mc java -Xms1024M -Xmx1536M -jar server.jar --nogui
