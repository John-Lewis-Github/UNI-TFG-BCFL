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
ruta=$chaincode_project_path
nombre_ultima_carpeta=$(basename $(readlink -f "$ruta"))

  echo "running script to install smartcontract on peer container"
  #run script installSC on container named cli and redirect error to output
  declare -a peer_addresses=()
echo "running script to install smartcontract on peer container"
echo "number of organizations: ${#org_names[@]}"

  for org_name in "${org_names[@]}"
    do
  echo "processing organization: $org_name"
  org_prefix="${org_name%%.*}"
  org_prefix="${org_prefix^}"
  echo "org_prefix value: $org_prefix"

  echo "creating temporary variable for peer address and TLS root certificate file"
  peer_address="--peerAddresses peer0.${org_name}:7051 --tlsRootCertFiles /etc/crypto-config/peerOrganizations/${org_name}/peers/peer0.${org_name}/tls/ca.crt"
  echo "peer_address value: $peer_address"

  echo "adding temporary variable to peer addresses array"
  peer_addresses+=("$peer_address")
echo "peer_addresses array: ${peer_addresses[@]}"
docker container restart $(docker container ls -q -f name=cli)
sleep 20s
  echo "executing command to install smart contract on peer container"
  echo "CORE_PEER_ADDRESS: peer0.${org_name}:7051"
echo "CORE_PEER_LOCALMSPID: ${org_prefix}MSP"
echo "CORE_PEER_TLS_CERT_FILE: /etc/crypto-config/peerOrganizations/${org_name}/peers/peer0.${org_name}/tls/server.crt"
echo "CORE_PEER_TLS_KEY_FILE: /etc/crypto-config/peerOrganizations/${org_name}/peers/peer0.${org_name}/tls/server.key"
echo "CORE_PEER_TLS_ROOTCERT_FILE: /etc/crypto-config/peerOrganizations/${org_name}/peers/peer0.${org_name}/tls/ca.crt"
echo "CORE_PEER_MSPCONFIGPATH: /etc/crypto-config/peerOrganizations/${org_name}/users/Admin@${org_name}/msp"

  output=$(docker exec -e CORE_PEER_ADDRESS=peer0.${org_name}:7051 \
            -e CORE_PEER_LOCALMSPID=${org_prefix}MSP \
            -e CORE_PEER_TLS_CERT_FILE=/etc/crypto-config/peerOrganizations/${org_name}/peers/peer0.${org_name}/tls/server.crt \
            -e CORE_PEER_TLS_KEY_FILE=/etc/crypto-config/peerOrganizations/${org_name}/peers/peer0.${org_name}/tls/server.key \
            -e CORE_PEER_TLS_ROOTCERT_FILE=/etc/crypto-config/peerOrganizations/${org_name}/peers/peer0.${org_name}/tls/ca.crt \
            -e CORE_PEER_MSPCONFIGPATH=/etc/crypto-config/peerOrganizations/${org_name}/users/Admin@${org_name}/msp \
            -it cli bash -c  "/etc/scripts/installSC.sh $nombre_ultima_carpeta 1 peer0.${org_name} $CHANNEL_NAME" 2>&1)
echo "output of command to install smart contract on peer container:"
echo "$output"
number=1
  echo "checking if smart contract is already installed"
  if [[ $output == *"but new definition must be sequence"* ]]; then
    echo "smart contract already installed, adding new version"
    echo $output

# Guardar todas las ocurrencias del patrón en un array
mapfile -t numbers < <(echo "$output" | awk -F'but new definition must be sequence ' 'NF>1{print $2}' | grep -o -E '[[:digit:]]+')

# Acceder a la primera ocurrencia del array
number="${numbers[0]}"

    echo "NUMBER***"
    echo $number
    echo "NUMBER***"
    docker exec -e CORE_PEER_ADDRESS=peer0.${org_name}:7051 \
            -e CORE_PEER_LOCALMSPID=${org_prefix}MSP \
            -e CORE_PEER_TLS_CERT_FILE=/etc/crypto-config/peerOrganizations/${org_name}/peers/peer0.${org_name}/tls/server.crt \
            -e CORE_PEER_TLS_KEY_FILE=/etc/crypto-config/peerOrganizations/${org_name}/peers/peer0.${org_name}/tls/server.key \
            -e CORE_PEER_TLS_ROOTCERT_FILE=/etc/crypto-config/peerOrganizations/${org_name}/peers/peer0.${org_name}/tls/ca.crt \
            -e CORE_PEER_MSPCONFIGPATH=/etc/crypto-config/peerOrganizations/${org_name}/users/Admin@${org_name}/msp \
            -it cli bash -c  "/etc/scripts/installSC.sh $nombre_ultima_carpeta $number peer0.${org_name} $CHANNEL_NAME"  2>&1
  fi
done

echo "combining peer addresses into a single string"
PEERADDRESSES=$(echo "${peer_addresses[*]}")

org_prefix="${org_names[0]%%.*}"
org_prefix="${org_prefix^}"

echo "executing command to commit smart contract to the channel"
docker exec -e CORE_PEER_ADDRESS=peer0.${org_names[0]}:7051 \
            -e CORE_PEER_LOCALMSPID=${org_prefix}MSP \
            -e CORE_PEER_TLS_CERT_FILE=/etc/crypto-config/peerOrganizations/${org_names[0]}/peers/peer0.${org_names[0]}/tls/server.crt \
            -e CORE_PEER_TLS_KEY_FILE=/etc/crypto-config/peerOrganizations/${org_names[0]}/peers/peer0.${org_names[0]}/tls/server.key \
            -e CORE_PEER_TLS_ROOTCERT_FILE=/etc/crypto-config/peerOrganizations/${org_names[0]}/peers/peer0.${org_names[0]}/tls/ca.crt \
            -e CORE_PEER_MSPCONFIGPATH=/etc/crypto-config/peerOrganizations/${org_names[0]}/users/Admin@${org_names[0]}/msp \
            -it cli bash -c  "bash /etc/scripts/commit.sh $nombre_ultima_carpeta $number peer0.${org_names[0]} $CHANNEL_NAME \"$PEERADDRESSES\""
