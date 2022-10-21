#!/bin/bash
#
# Bash script to automatically batch delete Virtual Machines in Azure Cloud resource group.
#

# ========= Settings =========
# Can be overriden by setting ENV variables before running this script

# Resource group to be deleted
RESOURCE_GROUP_NAME=${RESOURCE_GROUP_NAME:="azure-fleet-rg"}

#==============================

# ========= Helpers ===========

function check_error() {
  EXITCODE=$?
  if [ "$EXITCODE" -ne "0" ]; then
    #this is the catch part
    exit $EXITCODE
  fi
}

#==============================

echo "This script will delete resource group $RESOURCE_GROUP_NAME in your current azure account."
az account show
check_error
echo " "
echo "Resources to be deleted:"
az resource list --resource-group $RESOURCE_GROUP_NAME -o table
check_error
echo " "

az group delete --name $RESOURCE_GROUP_NAME --force-deletion-types Microsoft.Compute/virtualMachines --yes
check_error

echo "Script finished."

exit 0
