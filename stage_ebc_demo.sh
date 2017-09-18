#!/bin/bash
# Script for setting up the Tweeter demo in DC/OS
#
# Usage: DCOS_URL=http://<IP-address> DCOS_EE=[true/false] bash stage_ebc_demo.sh
# Alt Usage: bash stage_ebc_demo.sh [masterip] [publicELB]

# Requirements:
#   - DC/OS cluster with 1 public slave and 5 private slaves with
#       or without superuser set
#   - DCOS CLI installed on localhost
#   - DCOS_EE set to true or false
#   - DCOS_URL set to DCOS master URL
#
# If no user credentials are supplied, the following will be used:
#   Enterprise:
#     - AWS default bootstrapuser/deleteme
#     - Override with DCOS_USER & DCOS_PW
#   OSS:
#     - The token hard-coded below for mesosphere.user@gmail.com
#         password: unicornsarereal
#     - Override with DCOS_AUTH_TOKEN
set -o errexit

if [ -z ${DCOS_EE+x} ]; then DCOS_EE=true; fi
if [ -z ${DCOS_URL+x} ]; then
#strip http(s) from Master IP url
mip_clean=${1#*//}
#strip trailing slash from Master IP url
DCOS_URL=http://${mip_clean%/}
fi

if [ -z ${DCOS_PUB_ELB+x} ]; then
# strip http(s) from ELB url
elb_clean=${2#*//}
# strip trailing slash from ELB url
DCOS_PUB_ELB=${elb_clean%/}
fi

echo $DCOS_URL
echo $DCOS_PUB_ELB

#Run CI Script in infrastructure mode
for i in `dcos cluster list | awk ' FNR > 1 { print $1 }'`; do dcos cluster remove $i; done

bash cli_script.sh --url $DCOS_URL --infra

