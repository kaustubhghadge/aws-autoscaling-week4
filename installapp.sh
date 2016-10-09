#!/bin/bash
sudo apt-get update -y
sudo apt-get install -y apache2
sudo apt-get install -y git

sudo systemctl enable apache2
sudo systemctl start apache2

git clone https://github.com/kaustubhghadge/aws-ec2-week3.git


cd /var/www/html/

sudo rm -R -f *

sudo mv -v -f ~/aws-ec2-week3/* /var/www/html/


