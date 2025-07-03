#!/bin/bash
declare -a org_names=()
org_names+=("org1.example.com")
org_names+=("org2.example.com")
WORKSPACE=${PWD}
CHANNEL_NAME=mychannel
SCRIPTS_PATH=${PWD}/scripts
CHANNEL_ARTIFACTS_PATH=${PWD}/channel-artifacts

CONFIGTX_PATH=configtx.yaml
CRYPTO_CONFIG_PATH=${PWD}/crypto-config
ORDERER_DOMAIN="orderer.example.com"
CONNECTION_PROFILE_FILE="connection-profile.json"
HOSTS_FILE="hosts" 
chaincode_project_path=/home/fldlt/chaincode/FLSC/build/install/FLSC/


cd $chaincode_project_path
  ruta=$chaincode_project_path
  nombre_ultima_carpeta=$(basename $(readlink -f "$ruta"))
  cp -r ../$nombre_ultima_carpeta $WORKSPACE/chaincode/$nombre_ultima_carpeta
