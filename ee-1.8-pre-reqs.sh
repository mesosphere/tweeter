#!/bin/bash
#
# cat '%wheel         ALL = (ALL) NOPASSWD: ALL' >> /etc/sudoers

systemctl stop firewalld && sudo systemctl disable firewalld

yum upgrade --assumeyes --tolerant

yum install --assumeyes --tolerant tar xz unzip curl ipset

yum update --assumeyes

ntptime

adjtimex -p

timedatectl

sed -i s/SELINUX=enforcing/SELINUX=permissive/g /etc/selinux/config

groupadd nogroup

mkdir -p /core/genconf


tee /etc/modules-load.d/overlay.conf <<-'EOF'
overlay
EOF

tee /etc/yum.repos.d/docker.repo <<-'EOF'
[dockerrepo]
name=Docker Repository
baseurl=https://yum.dockerproject.org/repo/main/centos/7/
enabled=1
gpgcheck=1
gpgkey=https://yum.dockerproject.org/gpg
EOF

mkdir -p /etc/systemd/system/docker.service.d && tee /etc/systemd/system/docker.service.d/override.conf <<-'EOF'
[Service]
ExecStart=
ExecStart=/usr/bin/docker daemon --storage-driver=overlay -H fd://
EOF

yum install -y docker-engine-1.11.2

systemctl enable docker

reboot
