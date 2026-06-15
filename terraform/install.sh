#!/bin/bash

sudo curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"

sleep 3
echo "finished"
sudo curl -LO "https://dl.k8s.io/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl.sha256"

sleep 3
echo "finished"
sudo echo "$(cat kubectl.sha256)  kubectl" | sha256sum --check
sleep 2
echo "finished"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
sleep 3
echo "finished"
sudo kubectl version --client --output=yaml
sleep 1
echo "finished"
sudo apt-get -y install unzip

sleep 5
echo "finished"
sudo curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"

sleep 4
echo "finished"
sudo unzip awscliv2.zip

sleep 25
echo "finished"
sudo ./aws/install

sleep 4
echo "finished"
sudo  /usr/local/bin/aws --version
echo "finished"