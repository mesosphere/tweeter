#!/bin/bash

master_ip=$1
public_slave_elb=$2

curl -s $master_ip | grep DC/OS > /dev/null

if [ $? -eq 0 ]
then
  echo $'\nMaster is up\n'
else
  echo $'\n*************\nPlease specify a valid master IP address\n\nUsage:  stage_ebc_demo.sh <master_ip_address> <public_slave_elb>\n*************\n'
  exit
fi

mkdir -p dcos && cd dcos && 
curl -s -O https://downloads.mesosphere.com/dcos-cli/install.sh 
bash ./install.sh . http://$master_ip <<< 'no'

./bin/dcos auth login
./bin/dcos package install marathon-lb <<< 'yes'
./bin/dcos package install cassandra
./bin/dcos package install kafka

sleep 10
while ! ./bin/dcos cassandra connection 2>/dev/null | grep -q "node-2" ; do
    echo $'\nWaiting for Cassandra connection.\n'
    sleep 15
done
echo $'\nCassandra is up.\n'

while ! ./bin/dcos kafka connection | grep -q "broker-2" ; do
    echo $'\nWaiting for Kafka connection.\n'
    sleep 15
done
echo $'\nKafka is up.\n'

cp ../tweeter.json ../tweeter_current.json
sed -i.bak s/PUBLIC_SLAVE_ELB/$public_slave_elb/g ../tweeter_current.json

./bin/dcos marathon app add ../tweeter_current.json 

while ! curl -s $public_slave_elb | grep -q "weet" ; do
    echo $'\nWaiting for Tweeter.\n'
    sleep 20
done

echo $'\nYou can now connect to Tweeter at:\n'
echo "http://$public_slave_elb"
echo $'\nYou can now run the following to post tweets:\n'
echo "dcos/bin/dcos marathon app add post-tweets.json"
echo $'\nAfter installing Zeppelin connect with:\n'
echo "https://$master_ip/service/zeppelin"


