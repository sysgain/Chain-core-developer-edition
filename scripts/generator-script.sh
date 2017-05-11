#Usage : sh generator.sh <ip/dnsname of the signer VM>

#!/bin/bash

clienttokenname=$1
networktokenname=$2
serviceprincipal=$3
secretkey=$4
tenatid=$5
subscriptionid=$6
keyvaultname=$7
# install prerequisites 
apt-get update && apt-get install -y libssl-dev libffi-dev python-dev build-essential && apt-get install -y nodejs-legacy && apt-get install -y npm

echo "deb [arch=amd64] https://packages.microsoft.com/repos/azure-cli/ wheezy main" | \
     sudo tee /etc/apt/sources.list.d/azure-cli.list
sudo apt-key adv --keyserver packages.microsoft.com --recv-keys 417A0893
sudo apt-get install apt-transport-https
sudo apt-get update && sudo apt-get install azure-cli
sudo apt-get update && sudo apt-get install azure-cli


# pull chaincore docker image
docker pull chaincore/developer:latest
# run chaincore docker image
docker run -d -p 1999:1999 chaincore/developer:latest
sleep 60
containerId=`docker ps | cut -d " " -f1 | sed 1d`


#generator client access token / public key
docker exec  $containerId /usr/bin/chain/cored
generatorctoken=`docker exec  $containerId /usr/bin/chain/corectl create-token $clienttokenname | cut -c1-71`

#generator blockchain_id
chaincoreid=`docker exec  $containerId /usr/bin/chain/corectl config-generator | cut -c14-78`

echo $chaincoreid
sudo docker restart $containerId
sleep 30
#a network token that will be used by remote signers

networkToken=`docker exec  $containerId /usr/bin/chain/corectl create-token -net $networktokenname | cut -c1-71`


az login --service-principal -u $serviceprincipal -p $secretkey --tenant $tenatid
az account set -s $subscriptionid
echo "test az"
az keyvault secret set --name genclientToken --vault-name $keyvaultname --value $generatorctoken
echo "test keyvalt"
az keyvault secret set --name networkToken   --vault-name $keyvaultname --value $networkToken
echo "test escape"
az keyvault secret set --name chaincoreid   --vault-name $keyvaultname --value $chaincoreid
echo "test bid"
