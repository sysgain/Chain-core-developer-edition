#!/bin/bash

networktokenname=$1
serviceprincipal=$2
secretkey=$3
tenatid=$4
subscriptionid=$5
keyvaultname=$6
nodecount=$7

# install prerequisites 
apt-get update && apt-get install -y libssl-dev libffi-dev python-dev build-essential && apt-get install -y nodejs-legacy && apt-get install -y npm

echo "deb [arch=amd64] https://packages.microsoft.com/repos/azure-cli/ wheezy main" | \
     sudo tee /etc/apt/sources.list.d/azure-cli.list
sudo apt-key adv --keyserver packages.microsoft.com --recv-keys 417A0893
sudo apt-get install apt-transport-https
sudo apt-get update && sudo apt-get install azure-cli
sudo apt-get update && sudo apt-get install azure-cli


# Pull chaincore docker image
docker pull chaincore/developer:latest
# Run chaincore docker container
docker run -d -p 1999:1999 chaincore/developer:latest
sleep 40
containerId=`docker ps | cut -d " " -f1 | sed 1d`
count=1


docker exec -itd $containerId /usr/bin/chain/cored
# Retrieve client token from docker logs
generatorctoken=`docker logs $containerId | grep "^client:" | uniq`

# Generator blockchain_id
chaincoreid=`docker exec $containerId /usr/bin/chain/corectl config-generator`

docker restart $containerId
sleep 30

az login --service-principal -u $serviceprincipal -p $secretkey --tenant $tenatid
az account set -s $subscriptionid

ntokenamelen=`echo "$networktokenname${count}:" | wc -c`
totallen=`expr 65 + $ntokenamelen`

while [ $count -le $nodecount ]
do
  #a network token that will be used by remote signers
  networkToken=`docker exec $containerId /usr/bin/chain/corectl create-token -net $networktokenname${count} | cut -c1-$totallen`
  az keyvault secret set --name networkTokenSignerVM${count}   --vault-name $keyvaultname --value $networkToken
  count=`expr $count + 1`
done

az keyvault secret set --name genClientToken --vault-name $keyvaultname --value $generatorctoken
az keyvault secret set --name blockchainId   --vault-name $keyvaultname --value $chaincoreid
