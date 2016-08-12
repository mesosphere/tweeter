#!/bin/bash
set -o errexit

ci_oauth_token='eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1NiIsImtpZCI6Ik9UQkVOakZFTWtWQ09VRTRPRVpGTlRNMFJrWXlRa015Tnprd1JrSkVRemRCTWpBM1FqYzVOZyJ9.eyJlbWFpbCI6ImFsYmVydEBiZWtzdGlsLm5ldCIsImVtYWlsX3ZlcmlmaWVkIjp0cnVlLCJpc3MiOiJodHRwczovL2Rjb3MuYXV0aDAuY29tLyIsInN1YiI6Imdvb2dsZS1vYXV0aDJ8MTA5OTY0NDk5MDExMTA4OTA1MDUwIiwiYXVkIjoiM3lGNVRPU3pkbEk0NVExeHNweHplb0dCZTlmTnhtOW0iLCJleHAiOjIwOTA4ODQ5NzQsImlhdCI6MTQ2MDE2NDk3NH0.OxcoJJp06L1z2_41_p65FriEGkPzwFB_0pA9ULCvwvzJ8pJXw9hLbmsx-23aY2f-ydwJ7LSibL9i5NbQSR2riJWTcW4N7tLLCCMeFXKEK4hErN2hyxz71Fl765EjQSO5KD1A-HsOPr3ZZPoGTBjE0-EFtmXkSlHb1T2zd0Z8T5Z2-q96WkFoT6PiEdbrDA-e47LKtRmqsddnPZnp0xmMQdTr2MjpVgvqG7TlRvxDcYc-62rkwQXDNSWsW61FcKfQ-TRIZSf2GS9F9esDF4b5tRtrXcBNaorYa9ql0XAWH5W_ct4ylRNl3vwkYKWa4cmPvOqT5Wlj9Tf0af4lNO40PQ'
AUTH_TOKEN={$DCOS_AUTH_TOKEN:=$ci_auth_token}
DCOS_USER={$DCOS_USER:=bootstrapuser}
DCOS_PW={$DCOS_PW:=deleteme}
DCOS_EE=false

is_running() {
    status=`dcos marathon app list | grep $1 | awk '{print $6}'`
    if [ $status == '---' ]; then
        return 0
    else
        return 1
    fi
}

wait_for_deployment() {
    for service in $*; do
        until is_running $service; do
            echo "Wait for $service to finsh deploying..."
            sleep 3
        done
    done
}

ee_login() {
cat <<EOF | expect -
spawn dcos auth login
expect "username:"
send "$DCOS_USER\n"
expect "password:"
send "$DCOS_PW\n"
expect eof
EOF
}

oss_login() {
cat <<EOF | expect -
spawn dcos auth login
expect "token:"
send "$DCOS_AUTH_TOKEN\n"
expect eof
EOF

}

# Check DC/OS CLI is actually installed
dcos --help &> /dev/null || ( echo 'DC/OS must be installed!' && exit 1 )

# Setup access to the desired DCOS cluster and install marathon lb
dcos config set core.dcos_url $DCOS_URL
if $DCOS_EE; then
    ee_login
    cat <<EOF > get_sa.json
{
  "id": "/saread",
  "cmd": "cat /run/dcos/etc/mesos/agent_service_account.json\nsleep 36000",
  "instances": 1,
  "cpus": 0.1,
  "mem": 32,
  "user": "root"
}
EOF
    dcos marathon app add get_sa.json
    wait_for_deployment saread
    sa_token=`dcos task log --lines=1 saread`
    dcos marathon app remove saread
    # need to set up marathon LB... how to get service account?
else
    oss_login
    cat <<EOF | expect -
spawn dcos package install marathon-lb
expect {
    "\[yes\/no\]" {
        send "yes\n"
        expect eof
    }
    eof
}
EOF
   #dcos package install marathon-lb
fi
dcos package install cassandra
dcos package install kafka
dcos package install zeppelin

# query until services are listed as running
wait_for_deployment marathon-lb cassandra kafka zeppelin

# once running, deploy tweeter app and then post to it
dcos marathon app add tweeter.json
wait_for_deployment tweeter

dcos marathon app add post-tweets.json
wait_for_deployment post-tweets

# get the public IP of the public node if unset
cat <<EOF > public-ip.json
{
  "id": "/public-ip",
  "cmd": "curl http://169.254.169.254/latest/meta-data/public-ipv4 && sleep 3600",
  "cpus": 0.25,
  "mem": 32,
  "instances": 1,
  "acceptedResourceRoles": [
    "slave_public"
  ]
}
EOF
dcos marathon app add public-ip.json
wait_for_deployment public-ip
public_ip=`dcos task log --lines=1 public-ip`
dcos marathon app remove public-ip

# Now that tweets have been posted and the site is up, make sure it all works:
tweet_count=`curl -sSlvf $public_ip:10000 | grep 'class="tweet-content"' | wc -l`
if [ $tweet_count > 0 ]; then
    echo "Tweeter is up and running; $tweet_count tweets shown"
    exit 0
else
    echo "Failure: No tweets found!"
    exit 1
fi
