#!/bin/bash

#  Description: This script is intended to be used in conjunction with the
#+    Rackspace Passport service to aid in setting up SSH tunneling for DB
#+    access to a private RDS instance. (For use on both Linux and Mac)
#+
#+    --- The Rackspace Passport service provides a secure connection to 
#+    private resources within a Rackspace managed AWS account.
#+
#+    --- To set up a secure connection a user must first fill out an Access
#+    Request form (via web UI). This results in a "Login" link of which the url
#+    value can be copied to the clipboard and then used by executing this
#+    script to create a secure SSH tunnel from your local machine to a private
#+    RDS instance.
#+
#+    --- The expected format of the url value is the following:
#+    "scaleft://access/ssh?team=<team_id>&target=<target_id>&via=<bastion_id>"
#+
#+    --- This script can be used to establish simultaneous SSH tunnels to one
#+    or more private RDS instances (per AWS region and app environment combo)
#+
#+ Required for use:
#+     1) Rackspace user account where permissions are set to...
#+            AWS Account / Fanatical Support for AWS = Admin
#+     2) Passport service url: https://manage.rackspace.com/aws/passport
#+     3) (Linux only) Package: xclip (allows using values from system clipboard)
#+           "sudo apt-get install -y xclip"

#  Set listening port on private RDS instance
#+
#+ Example port is default for PostgreSQL RDS

RDS_PORT="5432"

#  Helper function

errexit () {
    echo "Error: $(basename "$0") (line ${BASH_LINENO}):" 1>&2
    echo "${1:-"Unknown Error"}" 1>&2
    exit 1
}

#  Determine OS-specific command to paste value from system clipboard

if [[ $(uname -a | grep Linux | wc -l) -eq 1 ]]; then
    # Linux command
    PASTE_CMD="xclip -selection primary -o"
else
    # Mac command
    PASTE_CMD="pbpaste"
fi

#  Make sure system clipboard contains expected URL value

if [[ $(${PASTE_CMD}) != scaleft* ]]; then
    errexit """
    A valid Passport Login URL was not found in the clipboard.

    Remember to FIRST right-click the \"Login\" link next to the DBJump server
      AWS Resource on the Passport Access Request page and select \"Copy link
      address\" to copy the expected URL to the clipboard BEFORE running this
      script! :)
    """
fi

#  Pull IDs for Bastion and Target from copied DBJump server Passport Login url

SCALEFT_URL=$(${PASTE_CMD}) || errexit "Error pasting url value from clipboard."
BASTION_ID=${SCALEFT_URL##*via=}
PART_SCALEFT_URL=${SCALEFT_URL##*target=}
TARGET_ID=${PART_SCALEFT_URL%%&via=*}

echo
echo "Passport Access Request information:"
echo "  Bastion ID  = ${BASTION_ID}"
echo "  Target ID   = ${TARGET_ID}"
echo

#  Determine Region and Environment in which to establish DB access 

AWS_REGION=$(sft ssh \
    --via ${BASTION_ID} ${TARGET_ID} \
    --command "curl --silent \
        http://169.254.169.254/latest/dynamic/instance-identity/document |
        jp region |
        tr -d '\"' |
        tr -d '\n'"
) || errexit "Error determining AWS Region."

echo
echo "AWS Region identified."
echo

MAC_ADDR=$(sft ssh \
    --via ${BASTION_ID} ${TARGET_ID} \
    --command "curl --silent \
        http://169.254.169.254/latest/meta-data/network/interfaces/macs/"
) || errexit "Error determining DBJump server ENI MAC address."

VPC_ID=$(sft ssh \
    --via ${BASTION_ID} ${TARGET_ID} \
    --command "curl --silent \
        http://169.254.169.254/latest/meta-data/network/interfaces/macs/${MAC_ADDR}vpc-id"
) || errexit "Error determining AWS VPC ID."

echo
echo "AWS VPC identified."
echo

APP_ENVIRONMENT=$(sft ssh \
    --via ${BASTION_ID} ${TARGET_ID} \
    --command "aws ec2 describe-vpcs \
        --vpc-ids ${VPC_ID} \
        --region ${AWS_REGION} \
        --query \"Vpcs[].Tags[?Key=='Environment'].Value[]\" \
        --output text |
        tr -d '\n'"
) || errexit "Error determining App Environment."

echo
echo "App Environment identified."
echo

#  Determine local port to forward
#+
#+ Example scenario shows two possible AWS regions (us-east-1 and us-west-1)
#+   and two possible app environments (Dev and Prod)

case "${AWS_REGION}" in
    "us-east-1" )
        case "${APP_ENVIRONMENT}" in
            "Dev" )
                LOCAL_PORT="6432"
                RDS_DNS="<private_dev_rds_endpoint>"
                ;;
            "Prod" )
                LOCAL_PORT="7432"
                RDS_DNS="<private_prod_rds_endpoint>"
                ;;
            * )
                errexit "A valid App Environment was not indentified."
                ;;
        esac
        ;;
    "us-west-1" )
        case "${APP_ENVIRONMENT}" in
            "Dev" )
                LOCAL_PORT="8432"
                RDS_DNS="<private_dev_rds_endpoint>"
                ;;
            "Prod" )
                LOCAL_PORT="9432"
                RDS_DNS="<private_prod_rds_endpoint>"
                ;;
            * )
                errexit "A valid App Environment was not indentified."
                ;;
        esac
        ;;
    * )
        errexit "A valid AWS Region was not indentified."
        ;;
esac

#  Establish SSH Tunnel to provide DB access

echo
echo "--------------------------------------------------------------"
echo "----- Establishing SSH Tunnel Connection (for DB access) -----"
echo "--------------------------------------------------------------"
echo "AWS Region =                  ${AWS_REGION}"
echo "Environment =                 ${APP_ENVIRONMENT}"
echo "Local Port (Listening) --->   ${LOCAL_PORT}"
echo "--------------------------------------------------------------"
echo "--------------------------------------------------------------"
echo
echo

EXISTS=$(netstat -anp | grep -v tcp6 | grep :${LOCAL_PORT} | grep ssh | wc -l)

if [[ ${EXISTS} -ne 0 ]]; then
    errexit """
    It appears that you may already have an open SSH tunnel established.
    At least another process is already listening on port ${LOCAL_PORT}.
    And it may be for DB access to Region ${AWS_REGION}, ${APP_ENVIRONMENT}
      Environment.
    """
else
    sft ssh \
        --via ${BASTION_ID} \
        -L ${LOCAL_PORT}:${RDS_DNS}:${RDS_PORT} \
        ${TARGET_ID} ||
    errexit "Error establishing SSH tunnel. :/"
fi
