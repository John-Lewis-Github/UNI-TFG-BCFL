#!/bin/bash
# Generar el archivo configtx.yaml y los Genesis Blocks del Orderer y del Canal
declare -a org_names=()
org_names+=("org1.example.com")
org_names+=("org2.example.com")
CONFIGTX_PATH=configtx.yaml
CRYPTO_CONFIG_PATH=${PWD}/crypto-config
ORDERER_DOMAIN="orderer.example.com"
CONNECTION_PROFILE_FILE="connection-profile.json"
HOSTS_FILE="hosts"
CHANNEL_NAME=mychannel
    # Generar el Genesis Block del Orderer
    mkdir -p channel-artifacts/
    configtxgen -configPath ${PWD} -profile OneOrgOrdererGenesis -channelID system-channel -outputBlock channel-artifacts/genesis.block
    # Generar el archivo de configuración del canal
    configtxgen -configPath ${PWD} -profile MultiOrgChannel -outputCreateChannelTx channel-artifacts/${CHANNEL_NAME}.tx -channelID ${CHANNEL_NAME}
    # Crear el archivo de configuración para actualizar el anchor peer

    for org_name in "${org_names[@]}"; do
        org_prefix="${org_name%%.*}"
        org_prefix="${org_prefix^}"  # convierte la primera letra a mayúscula
        configtxgen -configPath ${PWD} -profile MultiOrgChannel -outputAnchorPeersUpdate "channel-artifacts/${org_prefix}MSPanchors.tx" -channelID ${CHANNEL_NAME} -asOrg "${org_prefix}MSP"
        done
    # Crear objeto para almacenar el perfil de conexión
    PROFILE='{ "name": "'"$CHANNEL_NAME"'", "version": "1.0.0", "channels": { "'"$CHANNEL_NAME"'": { "orderers": [ "'"$ORDERER_DOMAIN"'" ], "peers": {'

# Añadir cada organización al objeto del perfil de conexión
  for org_name in "${org_names[@]}"
    do
      PROFILE+=' "'"$org_name"'.peer": {}'
    done

  # Añadir cada organización como objeto en la sección de organizaciones
  PROFILE+=' }, "organizations": {'

  for org_name in "${org_names[@]}"
    do
      PROFILE+=' "'"$org_name"'": { "mspid": "'"$org_name"'MSP", "peers": [ "peer.'"$org_name"'" ], "certificateAuthorities": [ ""ca.'"$org_name"'" ] },'
    done

  # Eliminar la última coma de la lista de organizaciones y cerrar la sección
  PROFILE=${PROFILE%?}
  PROFILE+=' },'

  # Añadir cada peer de cada organización a la sección de peers
  PROFILE+=' "peers": {'
  for org_name in "${org_names[@]}"
  do
    peer_name="peer.$org_name"
    PROFILE+=' "'"$peer_name"'": { "url": "grpc://'"$peer_name"':7051", "grpcOptions": { "ssl-target-name-override": "'"$peer_name"'" }, "tlsCACerts": { "path": "'"$CRYPTO_CONFIG_PATH"'/peerOrganizations/'"$org_name"'/tlsca/tlsca.'"$org_name"'.pem" } },'
  done

  # Eliminar la última coma de la lista de peers y cerrar la sección
  PROFILE=${PROFILE%?}
  PROFILE+=' },'

  # Añadir cada orderer a la sección de orderers
  PROFILE+=' "orderers": { "'"$ORDERER_DOMAIN"'": { "url": "grpc://'"$ORDERER_DOMAIN"':7050", "grpcOptions": { "ssl-target-name-override": "'"$ORDERER_DOMAIN"'" }, "tlsCACerts": { "path": "'"$CRYPTO_CONFIG_PATH"'/ordererOrganizations/example.com/tlsca/tlsca.example.com-cert.pem" } } }'

  # Cerrar el objeto del perfil de conexión
  PROFILE+=' }'

  # Guardar el perfil de conexión en un archivo
  echo "$PROFILE" > "$CONNECTION_PROFILE_FILE"

  # Generar archivo de hosts
  echo "Ingresa la dirección IP donde se lanzarán los servicios:"
  read IP_ADDRESS

  echo "$IP_ADDRESS  $ORDERER_DOMAIN" > "$HOSTS_FILE"

  for org_name in "${org_names[@]}"
  do
    peer_name="$peer.org_name"
    echo "$IP_ADDRESS  $peer_name" >> "$HOSTS_FILE"
  done

    echo "Archivos generados:"
    echo "$CONNECTION_PROFILE_FILE"
    echo "$HOSTS_FILE"