#!/bin/bash

#launching new instances
aws ec2 run-instances --image-id $1 --key-name kghadge --security-group-ids sg-0210c77b --client-token $2 --instance-type t2.micro --user-data file://installapp.sh --placement AvailabilityZone=us-west-2b --count 3

#getting instance IDs with client token
instance_id =`aws ec2 describe-instances --filters "Name=client-token,Values=$2" --query 'Reservations[*].Instances[].InstanceID'`

echo $instance_id

#implementing wait
aws ec2 wait instance-running --instance-ids $instance_id

#create load balancer
aws elb create-load-balancer --load-balancer-name lb-itmo-544 --listeners Protocol=Http,LoadBalancerPort=80, InstanceProtocol=Http,InstancePort=80 --subnets subnet-4960482d --security-groups sg-0210c77b

#register instances to load balancer
aws elb register-instances-with-load-balancer --load-balancer-name lb-itmo-544 --instances $instance_id

#creating launch conifguration
aws autoscaling create-launch-configuration --launch-configuration-name webserver --image-id $1 --key-name kghadge --instance-type t2.micro --user-data file://installapp.sh --security-groups sg-0210c77b

#creating autoscaling group with capacity parameters
aws autoscaling create-auto-scaling-group --auto-scaling-group-name webservercap --launch-configuration-name webserver --availability-zones us-west-2b --min-size 0 --max-size 5 --desired-capacity 1

#attach running instances to auto scaling group
aws autoscaling attach-instances --instance-ids $instance_id --auto-scaling-group-name webservercap

#attach load balancer to autoscaling group
aws autoscaling attach-load-balancers --load-balancer-names lb-itmo-544 --auto-scaling-group-name webservercap
