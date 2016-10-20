#!/bin/bash
#
#cat '%wheel         ALL = (ALL) NOPASSWD: ALL' >> /etc/sudoers

echo "Starting pre-req process"

systemctl stop firewalld && systemctl disable firewalld

echo "Firewall shutdown"

yum upgrade --assumeyes --tolerant

echo "Yum upgrade complete"

yum install --assumeyes --tolerant tar xz unzip curl ipset

echo "tar xz unzip curl ipset install complete"

yum update --assumeyes --tolerant

echo "Yum update complete"

ntptime

adjtimex -p

timedatectl

echo "NTP Complete"

sed -i s/SELINUX=enforcing/SELINUX=permissive/g /etc/selinux/config

echo "SE Linux disabled"

groupadd nogroup

echo "nogroup Added"

mkdir -p ~core/genconf

echo "<core>/genconf created"

tee /etc/modules-load.d/overlay.conf <<-'EOF'
overlay
EOF

echo "Overlay config complete"

tee /etc/yum.repos.d/docker.repo <<-'EOF'
[dockerrepo]
name=Docker Repository
baseurl=https://yum.dockerproject.org/repo/main/centos/7/
enabled=1
gpgcheck=1
gpgkey=https://yum.dockerproject.org/gpg
EOF

echo "Docker repo added"

mkdir -p /etc/systemd/system/docker.service.d && tee /etc/systemd/system/docker.service.d/override.conf <<-'EOF'
[Service]
ExecStart=
ExecStart=/usr/bin/docker daemon --storage-driver=overlay -H fd://
EOF

echo "Docker systemd config complete"

yum install --assumeyes --tolerant docker-engine-1.11.2

echo "Docker installed"

systemctl enable docker

echo "Docker enabled"

#reboot
