#! /bin/bash
arr=(
breeze-icon-theme # for partitionmanager
gdebi-core  # for beyond compare
gedit
pulseaudio-
ttf-wqy-zenhei 
)
sudo apt install -y "${arr[@]}"
sudo touch /root/.Xauthority
