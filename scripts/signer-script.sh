#script to generate signin key and netwowrk token
#Usage : sh signer-script.sh <ip/dnsname of the signer VM>
#!/bin/bash

#host name of the signer vm
host=$1
port="1999"

# install the required packages
apt-get update && apt-get install -y libssl-dev libffi-dev python-dev build-essential && apt-get install -y nodejs-legacy && apt-get install -y npm

npm install -g azure-cli

# pull chaincore docker image
docker pull chaincore/developer:latest

# run chaincore docker image
docker run -itd -p 1999:1999 chaincore/developer:latest

containerId=`docker ps | cut -d " " -f1 |sed 1d`
# grab the client token of signer
export clientToken=`docker logs $containerId | grep client | cut -c22-`
docker exec -itd $containerId /bin/sh

#signer public key
docker exec -itd $containerId /usr/bin/chain/corectl reset
export signerpubkey=`docker exec -it $containerId /usr/bin/chain/corectl create-block-keypair`
export netToken=`docker exec -it $containerId /usr/bin/chain/corectl create-token -net foo`
networktoken=`echo $netToken | cut -c1-68`

signerccurl="https://$networktoken@$host:$port"

#connecting to keyvault and sending values to key Vault

azure login -u asebastian@sysgaininc.onmicrosoft.com -p Ashwinse2793
azure keyvault secret set --secret-name secretname1 --vault-name Chain-e5yge-keybunch --value $signerpubkey
azure keyvault secret set --secret-name secretname2 --vault-name Chain-e5yge-keybunch --value $signerccurl
azure keyvault secret set --secret-name secretname3 --vault-name Chain-e5yge-keybunch --value $clientToken