#!/bin/bash
#
# Bash script to automatically batch create Virtual Machines in Azure Cloud,
# in multiple regions and provision with Docker.
#

# ========= Settings =========
# Can be overriden by setting ENV variables before running this script

# Must be set as ENV variables before running this script
SSH_USER_NAME=${SSH_USER_NAME:=""}
SSH_PASSWORD=${SSH_PASSWORD:=""}

# One resource group will be created in Azure that will contain all virtual machines
RESOURCE_GROUP_NAME=${RESOURCE_GROUP_NAME:="azure-fleet-rg"}
RESOURCE_GROUP_REGION=${RESOURCE_GROUP_REGION:="eastus"}
INPUT_FILE_NAME=${INPUT_FILE_NAME:="create_azure_fleet.csv"}
RESULT_FILE_NAME=${RESULT_FILE_NAME:="azure_fleet.csv"}

#==============================

# ========= Helpers ===========

function check_error() {
  EXITCODE=$?
  if [ "$EXITCODE" -ne "0" ]; then
    #this is the catch part
    exit $EXITCODE
  fi
}

function parse_json() {
  echo $1 |
    sed -e 's/[{}]/''/g' |
    sed -e 's/", "/'\",\"'/g' |
    sed -e 's/" ,"/'\",\"'/g' |
    sed -e 's/" , "/'\",\"'/g' |
    sed -e 's/","/'\"---SEPERATOR---\"'/g' |
    awk -F=':' -v RS='---SEPERATOR---' "\$1~/\"$2\"/ {print}" |
    sed -e "s/\"$2\"://" |
    tr -d "\n\t" |
    sed -e 's/\\"/"/g' |
    sed -e 's/\\\\/\\/g' |
    sed -e 's/^[ \t]*//g' |
    sed -e 's/^"//' -e 's/"$//'
}

#==============================

# ========= Checks ============

# TODO: Check that cloud_init.yml exists

if [ -z "${SSH_USER_NAME}" ]; then
  echo "SSH_USER_NAME environment variable is not set."
  exit 1
else
  echo "SSH_USER_NAME check...ok"
fi

if [ -z "${SSH_PASSWORD}" ]; then
  echo "SSH_PASSWORD environment variable is not set."
  exit 1
else
  echo "SSH_PASSWORD check...ok"
fi

if [ -f "$INPUT_FILE_NAME" ]; then
  echo "INPUT_FILE_NAME check...ok"
else
  echo "Input file '$INPUT_FILE_NAME' not found, make sure you have specified a correct file path."
  exit 1
fi

echo " "
# Remove if exists and create a brand new result file
rm -f $RESULT_FILE_NAME
echo "vm_name,ip" >>$RESULT_FILE_NAME

echo "Creating resource group: $RESOURCE_GROUP_NAME"
# Create resource group
_=$(az group create --name $RESOURCE_GROUP_NAME --location $RESOURCE_GROUP_REGION)
check_error
echo "Done."
echo " "

function deploy() {
  row=$1
  region=$2
  name=$3
  size=$4
  max_price=$5
  vm_create_result=$(az vm create \
    --resource-group $RESOURCE_GROUP_NAME \
    --location $region \
    --name $name \
    --size $size \
    --accelerated-networking true \
    --nic-delete-option Delete \
    --nsg-rule SSH \
    --public-ip-sku Standard \
    --public-ip-address-allocation static \
    --os-disk-delete-option Delete \
    --image Canonical:0001-com-ubuntu-server-focal:20_04-lts-gen2:20.04.202210180 \
    --priority Spot \
    --eviction-policy Deallocate \
    --max-price $max_price \
    --authentication-type password \
    --admin-username $SSH_USER_NAME \
    --admin-password $SSH_PASSWORD \
    --custom-data cloud_init.yml)
  check_error
  public_ip_addr=$(parse_json "$vm_create_result", publicIpAddress)
  echo " "
  echo "VM #$row - Created"
  echo "VM #$row - Public IP address: $public_ip_addr"
  echo "$name,$public_ip_addr" >>$RESULT_FILE_NAME
}

# Create VMs
row=1
while IFS="," read -r region name size max_price; do
  echo "Creating virtual machine #$row"
  echo "Region: $region"
  echo "VM name: $name"
  echo "Size: $size"
  echo "Max price: $max_price"
  # runs each deployment in parallel, thus order of csv results does not match input csv
  deploy $row $region $name $size $max_price &
  echo " "
  ((row++))
done < <(tail -n +2 $INPUT_FILE_NAME)

# Wait till all processes finish
wait

echo "Script finished, you can find created servers in '$RESULT_FILE_NAME' file."
exit 0
