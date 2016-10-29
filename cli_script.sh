#!/bin/bash
set -o errexit
# Set stable package versions here
CASSANDRA_STABLE=${CASSANDRA_STABLE:='1.0.12-2.2.5'}
KAFKA_STABLE=${KAFKA_STABLE:='1.1.9-0.10.0.0'}
MARATHON_LB_STABLE=${MARATHON_LB_STABLE:='1.3.5'}
ZEPPELIN_STABLE=${ZEPPELIN_STABLE:='0.6.0'}

USAGE="$(basename "$0") [-h|--help] [--step --manual --stable --infra]
Script for setting up the Tweeter demo in DC/OS

Current Stable Package Versions:
    Cassandra: $CASSANDRA_STABLE
    Kafka: $KAFKA_STABLE
    Marathon-LB: $MARATHON_LB_STABLE
    Zeppelin: $ZEPPELIN_STABLE

Requirements:
    - DC/OS cluster with 1 public slave and 5 private slaves
    - DCOS CLI installed on localhost

Credentials:
    Enterprise
    - AWS default bootstrapuser/deleteme
    - Override with --user & --pw
    OSS
    - Super long lived OAuth token used in CI
    - Override with DCOS_AUTH_TOKEN set in env

Options:
    -h, --help  Prints this help message
    --stable    Runs with set stable packages listed above. To override,
                use the above key as an environment variable.
                E.G. CASSANDRA_STABLE='1.0.12-2.2.5' $(basename "$0")
    --infra     Exit after installing infrastructure for Tweeter and
                leave the installation of Tweeter app to user
    --step      Pause after all DC/OS actions until user acknowledges
    --manual    Do not actually run any of the steps (allows user to)
    --url       Target DC/OS master to run script against
    --oss       Target DC/OS installation is an Open Source deployment
    --user      DC/OS Enterprise username (default: bootstrapuser)
    --pw        DC/OS Enterprise password (default: deleteme)
    --cypress   Run cypress UI tests
                "
# Instantiate default options
USE_STABLE=false
INFRA_ONLY=false
STEP_MODE=false
MANUAL_MODE=false
DCOS_OSS=false
RUN_CYPRESS=false

# Command Line Handler
while [[ $# -gt 0 ]]; do
    key="$1"

    case $key in
        --stable)
            USE_STABLE=true ;;
        --infra)
            INFRA_ONLY=true ;;
        --step)
            STEP_MODE=true ;;
        --manual)
            MANUAL_MODE=true ;;
        --oss)
            DCOS_OSS=true ;;
        --cypress)
            RUN_CYPRESS=true ;;
        --url)
            DCOS_URL="$2"
            shift ;;
        --user)
            DCOS_USER="$2"
            shift ;;
        --pw)
            DCOS_PW="$2"
            shift ;;
        -h|--help)
            echo "$USAGE"
            exit 0 ;;
        *)
            echo "Unrecognized option: $key"
            echo "$USAGE" >&2
            exit 1 ;;
    esac
    shift
done

# Required input checks
if [[ -z $DCOS_URL ]]; then
    echo "DCOS_URL is not set! Provide with --url or DCOS_URL env-var"
    exit 1
fi

ci_auth_token='eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1NiIsImtpZCI6Ik9UQkVOakZFTWtWQ09VRTRPRVpGTlRNMFJrWXlRa015Tnprd1JrSkVRemRCTWpBM1FqYzVOZyJ9.eyJlbWFpbCI6ImFsYmVydEBiZWtzdGlsLm5ldCIsImVtYWlsX3ZlcmlmaWVkIjp0cnVlLCJpc3MiOiJodHRwczovL2Rjb3MuYXV0aDAuY29tLyIsInN1YiI6Imdvb2dsZS1vYXV0aDJ8MTA5OTY0NDk5MDExMTA4OTA1MDUwIiwiYXVkIjoiM3lGNVRPU3pkbEk0NVExeHNweHplb0dCZTlmTnhtOW0iLCJleHAiOjIwOTA4ODQ5NzQsImlhdCI6MTQ2MDE2NDk3NH0.OxcoJJp06L1z2_41_p65FriEGkPzwFB_0pA9ULCvwvzJ8pJXw9hLbmsx-23aY2f-ydwJ7LSibL9i5NbQSR2riJWTcW4N7tLLCCMeFXKEK4hErN2hyxz71Fl765EjQSO5KD1A-HsOPr3ZZPoGTBjE0-EFtmXkSlHb1T2zd0Z8T5Z2-q96WkFoT6PiEdbrDA-e47LKtRmqsddnPZnp0xmMQdTr2MjpVgvqG7TlRvxDcYc-62rkwQXDNSWsW61FcKfQ-TRIZSf2GS9F9esDF4b5tRtrXcBNaorYa9ql0XAWH5W_ct4ylRNl3vwkYKWa4cmPvOqT5Wlj9Tf0af4lNO40PQ'
DCOS_AUTH_TOKEN=${DCOS_AUTH_TOKEN:=$ci_auth_token}
DCOS_USER=${DCOS_USER:='bootstrapuser'}
DCOS_PW=${DCOS_PW:='deleteme'}

demo_eval() {
    if $MANUAL_MODE; then
        printf "### Execute the following command: ###\n\n"
        # replace % in arg with %% to prevent printf interpretation
        printf "${1//\%/\%\%}\n\n"
        printf "######################################\n"
    else
        log_msg "Executing: $1"
        eval $1
    fi
    user_continue
}

user_continue() {
if $STEP_MODE; then
    read -p 'Continue? (y/n) ' resp
    case $resp in
        y) return ;;
        n) exit 0 ;;
        *) user_continue ;;
    esac
fi
return
}

is_running() {
    status=`dcos marathon app list | grep $1 | awk '{print $6}'`
    if [[ $status = '---' ]]; then
        return 0
    else
        return 1
    fi
}

log_msg() {
    echo `date -u +'%D %T'`: $1
}

wait_for_deployment() {
    for service in $*; do
        until is_running $service; do
            log_msg "Wait for $service to finish deploying..."
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
expect "Token:"
send "$DCOS_AUTH_TOKEN\n"
expect eof
EOF
}

# Check DC/OS CLI is actually installed
dcos --help &> /dev/null || ( echo 'DC/OS must be installed!' && exit 1 )

# Setup access to the desired DCOS cluster and install marathon lb
log_msg "Setting DCOS CLI to use $DCOS_URL"
demo_eval "dcos config set core.dcos_url $DCOS_URL"
if $DCOS_OSS; then
    log_msg "Starting DC/OS OSS Demo"
    log_msg "Override default credentials with DCOS_AUTH_TOKEN"
    oss_login
else
    log_msg "Starting DC/OS Enterprise Demo"
    log_msg "Override default credentials with --user and --pw"
    demo_eval ee_login
    # Get the dcos EE CLI
    demo_eval 'dcos package install --cli --yes dcos-enterprise-cli'
    demo_eval 'dcos security org service-accounts keypair -l 4096 k.priv k.pub'
    demo_eval 'dcos security org service-accounts create -p k.pub -d "Marathon LB" dcos_marathon_lb'
    demo_eval 'dcos security secrets create-sa-secret k.priv dcos_marathon_lb marathon-lb'
    log_msg "Get auth headers to do calls outside of DC/OS CLI (ACLs)"
    auth_t=`dcos config show core.dcos_acs_token`
    log_msg "Received auth token: $auth_t"
    auth_h="Authorization: token=$auth_t"

    # Make our ACLs
    demo_eval "curl -skSL -X PUT -H 'Content-Type: application/json' -d '{\"description\":\"Marathon admin events\"}' -H \"$auth_h\" $DCOS_URL/acs/api/v1/acls/dcos:service:marathon:marathon:admin:events"
    demo_eval "curl -skSL -X PUT -H 'Content-Type: application/json' -d '{\"description\":\"Marathon all services\"}' -H \"$auth_h\" $DCOS_URL/acs/api/v1/acls/dcos:service:marathon:marathon:services:%252F"
    # Add our dcos_marathon_lb service account to the ACLs
    demo_eval "curl -skSL -X PUT -H \"$auth_h\" $DCOS_URL/acs/api/v1/acls/dcos:service:marathon:marathon:admin:events/users/dcos_marathon_lb/read"
    demo_eval "curl -skSL -X PUT -H \"$auth_h\" $DCOS_URL/acs/api/v1/acls/dcos:service:marathon:marathon:services:%252F/users/dcos_marathon_lb/read"

    cat <<EOF > options.json
{
  "marathon-lb": {
    "secret_name": "marathon-lb"
  }
}
EOF
fi

if $INFRA_ONLY; then
    install_packages=(marathon-lb cassandra kafka)
else
    install_packages=(marathon-lb cassandra kafka zeppelin)
fi

for pkg in ${install_packages[*]}; do
    cmd="dcos --log-level=ERROR package install --yes"
    if [[ $pkg = 'marathon-lb' ]] && ! $DCOS_OSS; then
        cmd="$cmd --options=options.json"
    fi
    cmd="$cmd $pkg"
    if $USE_STABLE; then
        key="${pkg^^}_STABLE"
        key="${key//-/_}" # replace - with _ for marathon-lb
        eval ver='$'$key
        cmd="$cmd --package-version=$ver"
    fi
    demo_eval "$cmd"
done

# query until services are listed as running
wait_for_deployment ${install_packages[*]}

# once running, deploy tweeter app and then post to it
demo_eval "dcos marathon app add tweeter.json"
wait_for_deployment tweeter

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
demo_eval "dcos marathon app add public-ip.json"
wait_for_deployment public-ip
public_ip=`dcos task log --lines=1 public-ip`
demo_eval "dcos marathon app remove public-ip"

log_msg "Tweeter home page can be found at: http://$public_ip:10000/"
log_msg "Zeppelin can be found at: $DCOS_URL/service/zeppelin"

if $INFRA_ONLY; then
    log_msg "To post to tweeter, do: dcos marathon app add post-tweets.json"
    log_msg "Infrastructure setup complete! Exiting setup..."
    exit 0
fi

demo_eval "dcos marathon app add post-tweets.json"
wait_for_deployment post-tweets

# short sleep to make sure tweets are posted
sleep 30

# Run cypress tests if user opted-in.
if $RUN_CYPRESS; then
  if $DCOS_OSS; then
cat <<EOF > ci-conf.json
{
  "tweeter_url": "${public_ip}:10000",
  "url": "${DCOS_URL}"
}
EOF
  else
cat <<EOF > ci-conf.json
{
  "tweeter_url": "${public_ip}:10000",
  "url": "${DCOS_URL}",
  "username": "${DCOS_USER}",
  "password": "${DCOS_PW}"
}
EOF
  fi

  if (cypress --help &> /dev/null); then
    log_msg "Running cypress tests"
    demo_eval "yes | cypress run"
  else
    log_msg "cypress is not installed; skipping..."
  fi
fi

# Now that tweets have been posted and the site is up, make sure it all works:
log_msg "Pulling Tweets from $public_ip:10000"
tweet_count=`curl -sSlvf $public_ip:10000 | grep 'class="tweet-content"' | wc -l`
if [[ $tweet_count > 0 ]]; then
    log_msg "Tweeter is up and running; $tweet_count tweets shown"
    exit 0
else
    log_msg "Failure: No tweets found!"
    exit 1
fi
