#scrip will run on all the participant machines
#!/bin/bash
generatornodeip=$1
serviceprincipal=$2
secretkey=$3
tenatid=$4
subscriptionid=$5
keyvaultname=$6
participantclienttokenkeyname=$7
# install prerequisites 
echo "Installing prerequisites..........................................................................."
sudo apt-get update 
sudo apt-get install -y libssl-dev libffi-dev python-dev build-essential 
sudo apt-get install -y nodejs-legacy 
sudo apt-get install -y npm
echo "deb [arch=amd64] https://packages.microsoft.com/repos/azure-cli/ wheezy main" | sudo tee /etc/apt/sources.list.d/azure-cli.list
sudo apt-key adv --keyserver packages.microsoft.com --recv-keys 417A0893
sudo apt-get install apt-transport-https
sudo apt-get update 
echo "Installing Azure CLI 2.0..........................................................................."
sudo apt-get install azure-cli
sudo apt-get update 
sudo apt-get install azure-cli
echo "Logging into azure account.........................................................................."
az login --service-principal -u $serviceprincipal -p $secretkey --tenant $tenatid
az account set -s $subscriptionid
echo "Extracting generatornetworktoken and blockchainid from Azure Key Vault.............................."
generatornetworktoken=`az keyvault secret show --name networkToken --vault-name $keyvaultname | grep "value" | cut -d "\"" -f4`
blockchainid=`az keyvault secret show --name blockchainid --vault-name $keyvaultname | grep "value" | cut -d "\"" -f4`
# run chaincore docker image
docker run -d -p 1999:1999 chaincore/developer:latest
sleep 30
echo "Extracting container Id............................................................................."
containerId=`docker ps | cut -d " " -f1 | sed 1d`
#signer client access token / public key
docker exec -itd $containerId /usr/bin/chain/cored
#signerctoken=`docker exec  $containerId /usr/bin/chain/corectl create-token $clienttokenname | cut -c1-71`
echo "Genarating participant client token......................................................................"
participantctoken=`docker logs $containerId | grep "^client:" | uniq`
#signer config
response=`docker exec $containerId /usr/bin/chain/corectl config -t $generatornetworktoken  $blockchainid http://$generatornodeip:1999`
docker restart $containerId
echo "Storing participant token to the Azure Key Vault........................................................"
az keyvault secret set --name $participantclienttokenkeyname --vault-name $keyvaultname --value $participantctoken
