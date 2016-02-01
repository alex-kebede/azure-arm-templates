#!/bin/bash -e

# Encrypting Data Disk
SALT_ROOT_FS=/srv
DEVICE=/dev/sdc

if [ -f /root/crypted ]
then
  echo "${SALT_ROOT_FS} Already Encrypted."
else
  apt-get install -y cryptsetup
  if [ ! -d ${SALT_ROOT_FS} ]; then
    mkdir ${SALT_ROOT_FS}
  fi
  echo "/dev/mapper/luksdata ${SALT_ROOT_FS} ext4 defaults 0 2" >> /etc/fstab
  ssh-keygen -t rsa -b 4092 -N '' -f /etc/luks.key
  cryptsetup luksFormat -q --key-file=/etc/luks.key ${DEVICE}
  cryptsetup luksOpen --key-file=/etc/luks.key ${DEVICE} luksdata
  sleep 5
  mkfs.ext4 /dev/mapper/luksdata
  echo "luksdata UUID=$(blkid ${DEVICE} -s UUID -o value) /etc/luks.key  luks" >> /etc/crypttab
  mount ${SALT_ROOT_FS}
  touch /root/crypted
fi

# Setting Up Salt Repo
add-apt-repository -y ppa:saltstack/salt
apt-get update

# Installing Salt Server
apt-get install -y salt-master salt-minion salt-syndic

# Configuring Salt Server
/bin/sed -i 's/#auto_accept: False/auto_accept: True/g' /etc/salt/master
echo 'file_roots:\n  base:\n    - /srv/paas-salt/salt\npillar_roots:\n  base:\n    - /srv/paas-salt/pillar' >> /etc/salt/master
/usr/sbin/service salt-master restart

# Configuring Salt Minion
cat <<EOF > /etc/salt/minion
master: ${SALT_MASTER}
id:  salt-master.${POD_ID}.catalyzeapps.com
grains:
  ebs_disk: true
  cloud_provider: Azure
  pod_type: sbox
  pod_id: ${POD_ID}
EOF
/usr/sbin/service salt-minion restart
