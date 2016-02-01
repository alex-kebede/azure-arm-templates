#!/bin/bash -e

if [ -f /root/crypted ]
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

# Setting Up Salt Repo
add-apt-repository -y ppa:saltstack/salt
apt-get update

# Installing Salt Minion
apt-get install -y salt-minion

cat <<EOF > /etc/salt/minion
master: ${SALT_MASTER}
id:  ${VM_NAME}.${POD_ID}.catalyzeapps.com
grains:
  ebs_disk: true
  cloud_provider: Azure
  pod_type: sbox
  pod_id: ${POD_ID}
EOF
/usr/sbin/service salt-minion restart
