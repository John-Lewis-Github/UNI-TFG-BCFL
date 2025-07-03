#!/bin/bash
rest_project_path=/home/fldlt/ChainREST

echo "Actualizando certificados de config.json de API REST"
org1=org1.example.com

certificate=$( sed  -z -e 's|\n|\\\\n|g' ./crypto-config/peerOrganizations/$org1/users/User1@$org1/msp/signcerts/User1@$org1-cert.pem)
priv=$(sed  -z -e 's|\n|\\\\n|g' ./crypto-config/peerOrganizations/$org1/users/User1@$org1/msp/keystore/priv_sk)
#replace whole line containning substring "x" with "newline"
s1="s|\"certificate\":\\s*\".*$|\"certificate\": \"$certificate\",|g"
s2="s|\"privateKey\":\\s*\".*$|\"privateKey\": \"$priv\"|g"

sed  -i -r "$s1" $rest_project_path/routes/config.json
sed  -i -r "$s2" $rest_project_path/routes/config.json

rm -rf $rest_project_path/crypto-config
cp -R crypto-config $rest_project_path

sleep 10

echo "Desplegando docker API REST"

cd $rest_project_path
cd scripts
bash generate-docker-image.sh
bash run-chain-REST.sh