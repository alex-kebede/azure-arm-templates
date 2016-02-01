#!/bin/bash -e

if [ -a /root/crypted ]
then
  echo "/data Already Encrypted."
else
  apt-get install -y cryptsetup
  mkdir /data
  echo "/dev/mapper/luksdata /data ext4 defaults 0 2" >> /etc/fstab
  ssh-keygen -t rsa -b 4092 -N '' -f /etc/luks.key
  cryptsetup luksFormat -q --key-file=/etc/luks.key /dev/sdc
  cryptsetup luksOpen --key-file=/etc/luks.key /dev/sdc luksdata
  sleep 5
  mkfs.ext4 /dev/mapper/luksdata
  echo "luksdata UUID=$(blkid /dev/sdc -s UUID -o value) /etc/luks.key  luks" >> /etc/crypttab
  mount /data
  touch /root/crypted
fi
