#scrip will run on all the signer machines
#!/bin/bash
generatornodeip=$1
serviceprincipal=$2
secretkey=$3
tenatid=$4
subscriptionid=$5
keyvaultname=$6
signerclienttokenkeyname=$7
portnumber=$8
# install prerequisites 
echo "============================================Installing prerequisites============================================"
sudo apt-get update 
sudo apt-get install -y libssl-dev libffi-dev python-dev build-essential 
sudo apt-get install -y nodejs-legacy 
sudo apt-get install -y npm
echo "deb [arch=amd64] https://packages.microsoft.com/repos/azure-cli/ wheezy main" | sudo tee /etc/apt/sources.list.d/azure-cli.list
sudo apt-key adv --keyserver packages.microsoft.com --recv-keys 417A0893
sudo apt-get install apt-transport-https
sudo apt-get update 
echo "============================================Installing Azure CLI 2.0============================================="
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
echo "============================================Logging into azure account==========================================="
sudo az login --service-principal -u $serviceprincipal -p $secretkey --tenant $tenatid
sudo az account set -s $subscriptionid
echo "=================Extracting generatornetworktoken and blockchainid from Azure Key Vault==========================="
generatornetworktoken=`sudo az keyvault secret show --name networkToken --vault-name $keyvaultname | grep "value" | cut -d "\"" -f4`
blockchainid=`sudo az keyvault secret show --name blockchainid --vault-name $keyvaultname | grep "value" | cut -d "\"" -f4`
# pull chaincore docker image
sudo docker pull chaincore/developer:ivy-latest
# run chaincore docker image
sudo docker run -d -p $portnumber:1999 chaincore/developer:ivy-latest
sleep 60
echo "============================================Extracting container Id============================================="
containerId=`sudo docker ps | cut -d " " -f1 | sed 1d`
#signer client access token / public key
sudo docker exec -itd $containerId /usr/bin/chain/cored
#signerctoken=`sudo docker exec  $containerId /usr/bin/chain/corectl create-token $clienttokenname | cut -c1-71`
echo "============================================Genarating signer client token======================================="
signerctoken=`sudo docker logs $containerId | grep "^client:" | uniq`
signerctoken1=`echo $signerctoken | cut -c8-`
#signer config
response=`sudo docker exec $containerId /usr/bin/chain/corectl config -t $generatornetworktoken -k $signerctoken1 $blockchainid http://$generatornodeip:$portnumber`
sudo docker restart $containerId
echo "======================================Storing signer token to the Azure Key Vault==============================="
sudo az keyvault secret set --name $signerclienttokenkeyname --vault-name $keyvaultname --value $signerctoken
