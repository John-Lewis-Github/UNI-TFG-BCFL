 #!/bin/bash
declare -a org_names=()
org_names+=("org1.example.com")
org_names+=("org2.example.com")
CHANNEL_NAME=mychannel
for org_name in "${org_names[@]}"
  do
    org_prefix="${org_name%%.*}"
    org_prefix="${org_prefix^}"  # convierte la primera letra a mayúscula
    echo "Instalando canal en peer0.${org_name}..."
set -x
docker exec -e CORE_PEER_ADDRESS=peer0.${org_name}:7051 \
          -e CORE_PEER_LOCALMSPID=${org_prefix}MSP \
          -e CORE_PEER_TLS_CERT_FILE=/etc/crypto-config/peerOrganizations/${org_name}/peers/peer0.${org_name}/tls/server.crt \
          -e CORE_PEER_TLS_KEY_FILE=/etc/crypto-config/peerOrganizations/${org_name}/peers/peer0.${org_name}/tls/server.key \
          -e CORE_PEER_TLS_ROOTCERT_FILE=/etc/crypto-config/peerOrganizations/${org_name}/peers/peer0.${org_name}/tls/ca.crt \
          -e CORE_PEER_MSPCONFIGPATH=/etc/crypto-config/peerOrganizations/${org_name}/users/Admin@${org_name}/msp \
          cli bash -c "/etc/scripts/crearCanal.sh $CHANNEL_NAME ${org_prefix}MSPanchors.tx"
          

set +x

done


# Comprobar que todos los contenedores están en ejecución
echo "Todos los contenedores se han iniciado correctamente."