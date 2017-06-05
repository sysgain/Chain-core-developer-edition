#!/bin/bash
networktokenname=$1
serviceprincipal=$2
secretkey=$3
tenatid=$4
subscriptionid=$5
keyvaultname=$6
portnumber=$7
# install prerequisites 
echo "===========================================Installing prerequisites==========================================="
sudo apt-get update 
sudo apt-get install -y libssl-dev libffi-dev python-dev build-essential 
sudo apt-get install -y nodejs-legacy 
sudo apt-get install -y npm
echo "deb [arch=amd64] https://packages.microsoft.com/repos/azure-cli/ wheezy main" | sudo tee /etc/apt/sources.list.d/azure-cli.list
sudo apt-key adv --keyserver packages.microsoft.com --recv-keys 417A0893
sudo apt-get install apt-transport-https
sudo apt-get update 
echo "===========================================Installing Azure CLI 2.0==========================================="
sudo apt-get install azure-cli
sudo apt-get update
sudo apt-get install azure-cli
echo "===========================================Installing Docker=================================================="
sudo apt-get install -y apt-transport-https ca-certificates curl software-properties-common
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
sudo apt-get update
sudo apt-get install -y docker-ce
sudo systemctl enable docker
# pull chaincore docker image
sudo docker pull chaincore/developer:ivy-latest
# run chaincore docker image
sudo docker run -d -p $portnumber:1999 chaincore/developer:ivy-latest
sleep 60
echo "===========================================Extracting container Id==========================================="
containerId=`sudo docker ps | cut -d " " -f1 | sed 1d`
#generator client access token / public key
sudo docker exec -itd $containerId /usr/bin/chain/cored
#generatorctoken=`sudo docker exec  $containerId /usr/bin/chain/corectl create-token $clienttokenname | cut -c1-71`
echo "===========================================Genarating generator client token=================================="
generatorctoken=`sudo docker logs $containerId | grep "^client:" | uniq`
#generator blockchain_id
echo "===========================================Genarating generator blockchain ID================================="
chaincoreid=`sudo docker exec $containerId /usr/bin/chain/corectl config-generator`
sudo docker restart $containerId
sleep 30
echo "===========================================Logging into azure account========================================="
sudo az login --service-principal -u $serviceprincipal -p $secretkey --tenant $tenatid --allow-no-subscriptions
sudo az account set -s $subscriptionid
ntokenamelen=`echo "$networktokenname:" | wc -c`
totallen=`expr 65 + $ntokenamelen`
#a network token that will be used by remote signers
echo "===========================================Genarating generator network token=================================="
networkToken=`sudo docker exec $containerId /usr/bin/chain/corectl create-token -net $networktokenname | cut -c1-$totallen`
echo "=============Storing networkToken,generatorClientToken and blockchainid to the Azure Key Vault================="
sudo az keyvault secret set --name networkToken   --vault-name $keyvaultname --value $networkToken
sudo az keyvault secret set --name generatorClientToken --vault-name $keyvaultname --value $generatorctoken
sudo az keyvault secret set --name blockchainid   --vault-name $keyvaultname --value $chaincoreid
