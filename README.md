# natservers

In the project I've created a setting for deploying a cluster of 3 servers (using terraform) that will serve 
as nats-servers and make sure that the connection between them can be established.

## Requirements

Before you begin, ensure you have the following:

* Python 3: You'll need Python 3 installed on your system to run the testing script.

* Terraform: Make sure you have Terraform installed on your machine. 

* AWS Access Key and Secret Key: Configure your AWS access_key and secret_key to authenticate with your AWS account.

* Python Libraries: Install the required Python libraries listed in the `requirements.txt` file by running the following command:
  

      pip3 install -r requirements.txt

## Components

### Main.tf

The `main.tf` file defines the necessary resources to create a functional NATS servers cluster. It includes:

* A Virtual Private Cloud (VPC) and subnet to host the cluster.
* A route table and internet gateway for internet access.
* A security group to control communication between instances.
* A key pair for connecting to instances.
* 3 EC2 instances, each configured as a NATS server. The user data installs NATS server during instance launch.


### Outputs.tf

In `outputs.tf`, we store the public and private IP addresses assigned by Terraform to the instances. These IP addresses are used in the testing script.


### Test_connection.py

The `test_connection.py` Python script verifies that communication can be established between the NATS servers. It follows these steps:

1. Launch the first NATS server to act as the seed server.
2. Launch the other 2 servers and attempt to establish communication with the seed server.
3. Check for any errors in the server logs.
4. Perform cleanup by stopping the NATS servers service and deleting the logs.

To run the tests, execute the following command in your terminal:

    python test_connection.py