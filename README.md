# dbclient-rds-bridge

### Description
This scripting tool is intended to be used in conjunction with the Rackspace Passport service to aid in setting up SSH tunneling for DB admins to private RDS instances. (For use on both Linux and Mac)

(The Rackspace Passport service provides a secure connection to private resources within a Rackspace managed AWS account and is included in the Aviator level of their Fanatical AWS Support.)

### Instructions
1. Log in to a Rackspace/AWS account via a user with appropriate privileges.
2. Navigate to the Passport service and complete a Create Access Request form, making sure to select a private AWS EC2 instance which has been previously configured with security group rules allowing connections to the private RDS instance.
![Alt text](images/create_passport_access_request.png?raw=true "Passport Access Request Form") 
3. Allow 30-60 seconds for the Passport service to spin up a temporary bastion server in the AWS account.
4. Right-click the "Login" link next to the private AWS resource which was previously selected (step #2) and select the "Copy link address" option to copy the link to your clipboard.
![Alt text](images/passport_access_request.png?raw=true "Copy Login Link to Clipboard")
5. Run the dbbridge.sh script.


