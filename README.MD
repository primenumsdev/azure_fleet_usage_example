# Azure Fleet

Use GitHub actions to automatically batch create Virtual Machines in Azure Cloud, in multiple regions and provision with Docker.


## How to use it:

1. Create your own **private** repository using [this repo](https://github.com/primenumsdev/azure-fleet) as template.

   Click the "Use this template" button above.

2. Create GitHub Actions Secret for:
  - `AZURE_CREDENTIALS` - Service principal Azure credentials, JSON, see [wiki page how to get it](https://github.com/primenumsdev/azure-fleet/wiki/Get-Azure-Service-Principal-Credentials).

  - `SSH_PASSWORD` - Password to be used for SSH login to VMs.
    > The password length must be between 12 and 72. Password must have the 3 of the following: 1 lower case character, 1 upper case character, 1 number and 1 special character.
  
  - `SSH_USER_NAME` - Username to be used for SSH login to VMs.

3. Run GitHub Actions workflow:

  - `create_azure_fleet` - Create virtual machines according to the specification in `create_azure_fleet.csv`.

  - `delete_azure_fleet` - Delete virtual machines created by azure fleet.

