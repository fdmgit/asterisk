#!/bin/bash

######################################
######################################
####   Asterisk FreePBX Install   ####
######################################
######################################

apt update
apt -y upgrade


###########################
#  Install Webmin
###########################

cd /root
apt-get -y install perl libnet-ssleay-perl openssl libauthen-pam-perl libpam-runtime libio-pty-perl apt-show-versions unzip shared-mime-info
wget https://github.com/webmin/webmin/releases/download/2.021/webmin_2.021_all.deb
dpkg --install webmin_2.021_all.deb
rm webmin_2.021_all.deb


##############################
#  Some additional programs
##############################

apt install plocate -y
updatedb

echo "root:$1" | chpasswd   # set root password -
hostnamectl set-hostname $2 # set hostname

##############################
#  Install Asterisk 20
##############################

apt -y install git vim curl wget libnewt-dev libssl-dev libncurses5-dev subversion libsqlite3-dev build-essential libjansson-dev libxml2-dev uuid-dev
cd /usr/src/
wget https://downloads.asterisk.org/pub/telephony/asterisk/asterisk-20-current.tar.gz

tar xvf asterisk-20-current.tar.gz
rm asterisk-20-current.tar.gz
cd asterisk-20*/

contrib/scripts/get_mp3_source.sh
contrib/scripts/install_prereq install
./configure
make menuselect

make
make install
make progdocs
make samples
make config
ldconfig

sleep 30

cd /root

groupadd asterisk 
useradd -r -d /var/lib/asterisk -g asterisk asterisk 
usermod -aG audio,dialout asterisk 
sudo chown -R asterisk.asterisk /etc/asterisk 
sudo chown -R asterisk.asterisk /var/lib/asterisk
sudo chown -R asterisk.asterisk /var/log/asterisk
sudo chown -R asterisk.asterisk /var/spool/asterisk 
sudo chown -R asterisk.asterisk /usr/lib/asterisk


sed -i 's/#AST_USER="asterisk"/AST_USER="asterisk"/'  /etc/default/asterisk
sed -i 's/#AST_GROUP="asterisk"/AST_GROUP="asterisk"/'  /etc/default/asterisk

#sed -i 's/;runuser = asterisk /runuser = asterisk/'  /etc/asterisk/asterisk.conf
#sed -i 's/;rungroup = asterisk/rungroup = asterisk/'  /etc/asterisk/asterisk.conf
echo 'runuser = asterisk             ; The user to run as.' >> /etc/asterisk/asterisk.conf
echo 'rungroup = asterisk             ; The user to run as.' >> /etc/asterisk/asterisk.conf


systemctl restart asterisk
systemctl enable asterisk

echo 'Sleep now'
sleep 20
echo 'Sleep done'

systemctl restart asterisk

echo 'Sleep now'
sleep 10
echo 'Sleep done'

#asterisk -rvv

#source /root/inst-ast-p2.sh
