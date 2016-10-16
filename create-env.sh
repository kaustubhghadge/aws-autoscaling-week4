#!/bin/bash

# added positional parameters

val_one()
{
 check_image=`aws ec2 describe-images --image-ids $1`


if [-z "$check_image"];

then 
	echo "Error. Wrong image ID. If you're passing parameters follow the order below"
	echo "1. AMI ID, 2. Key-name 3. Security-group, 4. Launch-configuration, 5. Launch-configuration -min 1"
	exit 0;
fi
}

val_two()
{
check_key=`aws ec2 describe-key-pairs --key-name $1`

if [-z "$check_key"];
then

	echo "Error. Wrong key. If you're passing 5 parameters follow the order below"
	echo "1. AMI ID, 2. Key-name 3. Security-group, 4. Launch-configuration, 5. Launch-configuration -min 1"
	exit 0;
fi
}

val_three()
{
check_security=`aws ec2 describe-security-groups --group-ids $1`

if[-z "$check_security"];	
then
	echo "Error. Wrong security group ID. If you're passing 5 parameters follow the order below"
	echo "1. AMI ID, 2. Key-name 3. Security-group, 4. Launch-configuration, 5. Launch-configuration -min 1"
	exit 0;
fi
}

val_four()
{
check_launch=`aws autoscaling describe-launch-configurations --launch-configuration-names $1`

if[-z "check_launch"];
then

	echo "Error. Launch configuration error. If you're passing 5 parameters follow the order below"
	echo "1. AMI ID, 2. Key-name 3. Security-group, 4. Launch-configuration, 5. Launch-configuration -min 1"
	exit 0;
fi
}

val_five()
{
if [$1 -lt 1];
then

	echo "Error. Count should be minimum of 1. If you're passing 5 parameters follow the order below"
	echo "1. AMI ID, 2. Key-name 3. Security-group, 4. Launch-configuration, 5. Launch-configuration -min 1"
	exit 0;
fi
}

if[$# -eq 5]
then
echo "Checking parameters"
val_one $1
val_two $2
val_three $3
val_four $4
val_five $5

#launching new instances
aws ec2 run-instances --image-id $1 --key-name $2 --security-group-ids $3 --client-token kgtok --instance-type t2.micro --user-data file://installapp.sh --placement AvailabilityZone=us-west-2b --count $5

#getting instance IDs with client token
instance_id =`aws ec2 describe-instances --filters "Name=client-token,Values=kgtok" --query 'Reservations[*].Instances[].InstanceID'`

echo $instance_id

#implementing wait
aws ec2 wait instance-running --instance-ids $instance_id

#create load balancer
aws elb create-load-balancer --load-balancer-name lb-itmo-544 --listeners Protocol=Http,LoadBalancerPort=80, InstanceProtocol=Http,InstancePort=80 --subnets subnet-4960482d --security-groups $3

#register instances to load balancer
aws elb register-instances-with-load-balancer --load-balancer-name lb-itmo-544 --instances $instance_id

#creating launch conifguration
aws autoscaling create-launch-configuration --launch-configuration-name $4 --image-id $1 --key-name $2 --instance-type t2.micro --user-data file://installapp.sh --security-groups $3

#creating autoscaling group with capacity parameters
aws autoscaling create-auto-scaling-group --auto-scaling-group-name webservercap --launch-configuration-name $4 --availability-zones us-west-2b --min-size 0 --max-size 5 --desired-capacity 1

#attach running instances to auto scaling group
aws autoscaling attach-instances --instance-ids $instance_id --auto-scaling-group-name webservercap

#attach load balancer to autoscaling group
aws autoscaling attach-load-balancers --load-balancer-names lb-itmo-544 --auto-scaling-group-name webservercap

echo "Success"
fi