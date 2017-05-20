#!/bin/bash
networktokenname=$1
serviceprincipal=$2
secretkey=$3
tenatid=$4
subscriptionid=$5
keyvaultname=$6
# install prerequisites 
sudo apt-get update 
sudo apt-get install -y libssl-dev libffi-dev python-dev build-essential 
sudo apt-get install -y nodejs-legacy 
sudo apt-get install -y npm
echo "deb [arch=amd64] https://packages.microsoft.com/repos/azure-cli/ wheezy main" | sudo tee /etc/apt/sources.list.d/azure-cli.list
sudo apt-key adv --keyserver packages.microsoft.com --recv-keys 417A0893
sudo apt-get install apt-transport-https
sudo apt-get update 
sudo apt-get install azure-cli
sudo apt-get update
sudo apt-get install azure-cli
# pull chaincore docker image
docker pull chaincore/developer:ivy-latest
# run chaincore docker image
docker run -d -p 1999:1999 chaincore/developer:ivy-latest
sleep 30
containerId=`docker ps | cut -d " " -f1 | sed 1d`
#generator client access token / public key
docker exec -itd $containerId /usr/bin/chain/cored
#generatorctoken=`docker exec  $containerId /usr/bin/chain/corectl create-token $clienttokenname | cut -c1-71`
generatorctoken=`docker logs $containerId | grep "^client:" | uniq`
#generator blockchain_id
chaincoreid=`docker exec $containerId /usr/bin/chain/corectl config-generator`
docker restart $containerId
sleep 30
sudo az login --service-principal -u $serviceprincipal -p $secretkey --tenant $tenatid
sudo az account set -s $subscriptionid
ntokenamelen=`echo "$networktokenname:" | wc -c`
totallen=`expr 65 + $ntokenamelen`
#a network token that will be used by remote signers
networkToken=`docker exec $containerId /usr/bin/chain/corectl create-token -net $networktokenname | cut -c1-$totallen`
sudo az keyvault secret set --name networkTokenSignerVM   --vault-name $keyvaultname --value $networkToken
sudo az keyvault secret set --name generatorClientToken --vault-name $keyvaultname --value $generatorctoken
sudo az keyvault secret set --name blockchainid   --vault-name $keyvaultname --value $chaincoreid