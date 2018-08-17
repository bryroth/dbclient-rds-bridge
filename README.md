# dbclient-rds-bridge

### Description
This scripting tool is intended to be used in conjunction with the Rackspace Passport service to aid in setting up SSH tunneling for DB admins to private RDS instances. (For use on both Linux and Mac)

(The Rackspace Passport service provides a secure connection to private resources within a Rackspace managed AWS account and is included in the Aviator level of their Fanatical AWS Support.)

### Instructions
1. Log in to a Rackspace/AWS account via a user with appropriate privileges.
2. Navigate to the Passport service and complete a Create Access Request form, making sure to select a private AWS EC2 instance which has been previously configured with security group rules allowing connections to the private RDS instance.
3. Allow 30-60 seconds for the Passport service to spin up a temporary bastion server in the AWS account.
4. Right-click the "Login" link next to the private AWS resource which was previously selected (step #2) and select the "Copy link address" option to copy the link to your clipboard.
5. Run the dbbridge.sh script.

### Notes
* The expected format of the url value is the following:
..."scaleft://access/ssh?team=<team_id>&target=<target_id>&via=<bastion_id>"
* This script can be used to establish simultaneous SSH tunnels to one or more private RDS instances (per AWS region and app environment combo). 
* Requirements for use:
  1. Rackspace user account where permissions are set to "Admin" for AWS account/Fanatical support
  2. (Linux only) Package: xclip (allows using values from system clipboard)
* The script will provide appropriate messaging upon any errors occurring.
* Once an SSH tunnel has been established by the script, database access should be available to the private RDS by the database client using the following parameters:
  * Host = "localhost" or "127.0.0.1"
  * Port = <port_number_configured_in_script> (This should also be printed out if the script runs successfully.) 
