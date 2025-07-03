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

  index=6;
  for org_name in "${org_names[@]}"; do
    org_prefix="${org_name%%.*}"
    org_prefix="${org_prefix^}"  # convierte la primera letra a mayúscula

 ((index++))
    # Crear la carpeta para el peer de la organización
    mkdir -p docker-composes/peers/${org_name}/
    mkdir -p docker-composes/ca/${org_name}/

    # Crear el archivo de docker-compose.yml para el peer de la organización
    cat <<EOF > "docker-composes/peers/${org_name}/docker-compose.yml"
version: '3.4'

networks:
  local:
    name: fabric_local

volumes:
  peer0.${org_name}:

services:
  peer0.${org_name}:
    container_name: peer0.${org_name}
    image: hyperledger/fabric-peer:2.4
    environment:
      - CORE_VM_ENDPOINT=unix:///host/var/run/docker.sock
      - CORE_CHAINCODE_EXECUTETIMEOUT=30s
      - CORE_PEER_KEEPALIVE_DELIVERYCLIENT_TIMEOUT=30s
      - CORE_PEER_KEEPALIVE_CLIENT_TIMEOUT=30s
      - CORE_VM_DOCKER_HOSTCONFIG_NETWORKMODE=fabric_local
      - CORE_PEER_CHAINCODELISTENADDRESS=0.0.0.0:7052
      - FABRIC_LOGGING_SPEC=info
      - CORE_PEER_TLS_ENABLED=true
      - CORE_PEER_PROFILE_ENABLED=true
      - CORE_PEER_TLS_CERT_FILE=/etc/hyperledger/fabric/tls/server.crt
      - CORE_PEER_TLS_KEY_FILE=/etc/hyperledger/fabric/tls/server.key
      - CORE_PEER_TLS_ROOTCERT_FILE=/etc/hyperledger/fabric/tls/ca.crt
      - CORE_PEER_ID=peer0.${org_name}
      - CORE_PEER_ADDRESS=peer0.${org_name}:7051
      - CORE_PEER_GOSSIP_USELEADERELECTION=false
      - CORE_PEER_GOSSIP_ORGLEADER=true
      - CORE_PEER_GOSSIP_EXTERNALENDPOINT=peer0.${org_name}:7051
      - CORE_PEER_LOCALMSPID=${org_prefix}MSP
      - CORE_VM_DOCKER_ATTACHSTDOUT=true
      - CORE_CHAINCODE_STARTUPTIMEOUT=1200s
      - CORE_CHAINCODE_EXECUTETIMEOUT=800s
      - CORE_LEDGER_STATE_STATEDATABASE=CouchDB
      - CORE_LEDGER_STATE_COUCHDBCONFIG_COUCHDBADDRESS=couchdb.example.com:5984
      # The CORE_LEDGER_STATE_COUCHDBCONFIG_USERNAME and CORE_LEDGER_STATE_COUCHDBCONFIG_PASSWORD
      # provide the credentials for ledger to connect to CouchDB.  The username and password must
      # match the username and password set for the associated CouchDB.
      - CORE_LEDGER_STATE_COUCHDBCONFIG_USERNAME=admin
      - CORE_LEDGER_STATE_COUCHDBCONFIG_PASSWORD=adminpw
    restart: always
    working_dir: /opt/gopath/src/github.com/hyperledger/fabric/peer
    command: peer node start
    networks:
      - local

    volumes:
        - /var/run/:/host/var/run/
        - ${CRYPTO_CONFIG_PATH}/peerOrganizations/${org_name}/peers/peer0.${org_name}/msp:/etc/hyperledger/fabric/msp
        - ${CRYPTO_CONFIG_PATH}/peerOrganizations/${org_name}/peers/peer0.${org_name}/tls:/etc/hyperledger/fabric/tls
        - peer0.${org_name}:/var/hyperledger/production
    ports:
      - "$((index))051:7051"
      - "$((index))052:7052"
      - "$((index))053:7053"

EOF


    cat <<EOF > "docker-composes/ca/${org_name}/docker-compose.yml"
version: '3.4'

networks:
  local:
    name: fabric_local

services:
  ca.${org_name}:
    container_name: ca.${org_name}
    image: hyperledger/fabric-ca
    environment:
      - FABRIC_CA_HOME=/etc/hyperledger/fabric-ca-server
      - FABRIC_CA_SERVER_CA_NAME=ca-${org_prefix}
      - FABRIC_CA_SERVER_TLS_ENABLED=true
      - FABRIC_CA_SERVER_TLS_CERTFILE=/etc/hyperledger/fabric-ca-server-config/ca.${org_name}-cert.pem
      - FABRIC_CA_SERVER_TLS_KEYFILE=/etc/hyperledger/fabric-ca-server-config/priv_sk
      - FABRIC_CA_SERVER_PORT=7054
    ports:
      - "$((index))054:7054"
    command: sh -c 'fabric-ca-server start --ca.certfile /etc/hyperledger/fabric-ca-server-config/ca.${org_name}-cert.pem --ca.keyfile /etc/hyperledger/fabric-ca-server-config/priv_sk -b admin:adminpw -d'
    volumes:
      - ${WORKSPACE}/crypto-config/peerOrganizations/${org_name}/ca/:/etc/hyperledger/fabric-ca-server-config
    networks:
      - local
    restart: always
EOF


    mkdir -p docker-composes/cli/

    # Crear el archivo de docker-compose.yml para el peer de la organización
    cat <<EOF > "docker-composes/cli/docker-compose.yml"
version: '3.4'

networks:
  local:
    name: fabric_local

volumes:
  cli:


services:
  cli:
      container_name: cli
      image: hyperledger/fabric-tools:2.4
      tty: true
      stdin_open: true

      environment:

        - GOPATH=/opt/gopath
        - CORE_VM_ENDPOINT=unix:///host/var/run/docker.sock
        - FABRIC_LOGGING_SPEC=INFO
        - CORE_PEER_ID=cli
        - CORE_PEER_TLS_ENABLED=true
      working_dir: /etc/
      restart: always
      command: /bin/bash
      volumes:
          - /var/run/:/host/var/run/
          - ${WORKSPACE}/chaincode:/etc/chaincode:rw
          - ${WORKSPACE}/crypto-config:/etc/crypto-config
          - ${WORKSPACE}/scripts:/etc/scripts
          - ${WORKSPACE}/channel-artifacts:/etc/channel-artifacts
      networks:
        - local
EOF


mkdir -p docker-composes/orderers/
  cat > docker-composes/orderers/docker-compose-orderer.yml << EOF
version: '3.4'

networks:
  local:
    name: fabric_local

volumes:
  orderer.example.com:

services:
  orderer.example.com:
    container_name: orderer.example.com
    image: hyperledger/fabric-orderer:2.4
    environment:
      - FABRIC_LOGGING_SPEC=info
      - ORDERER_GENERAL_LISTENADDRESS=0.0.0.0
      - ORDERER_GENERAL_GENESISMETHOD=file
      - ORDERER_GENERAL_GENESISFILE=/var/hyperledger/orderer/orderer.genesis.block
      - ORDERER_GENERAL_LOCALMSPID=OrdererMSP
      - ORDERER_GENERAL_LOCALMSPDIR=/var/hyperledger/orderer/msp
      - ORDERER_GENERAL_TLS_ENABLED=true
      - ORDERER_GENERAL_TLS_PRIVATEKEY=/var/hyperledger/orderer/tls/server.key
      - ORDERER_GENERAL_TLS_CERTIFICATE=/var/hyperledger/orderer/tls/server.crt
      - ORDERER_GENERAL_TLS_ROOTCAS=[/var/hyperledger/orderer/tls/ca.crt]
      - ORDERER_GENERAL_CLUSTER_CLIENTCERTIFICATE=/var/hyperledger/orderer/tls/server.crt
      - ORDERER_GENERAL_CLUSTER_CLIENTPRIVATEKEY=/var/hyperledger/orderer/tls/server.key
      - ORDERER_GENERAL_CLUSTER_ROOTCAS=[/var/hyperledger/orderer/tls/ca.crt]
    working_dir: /opt/gopath/src/github.com/hyperledger/fabric/orderer
    command: orderer
    volumes:
      - ${CRYPTO_CONFIG_PATH}/ordererOrganizations/example.com/orderers/orderer.example.com/msp:/var/hyperledger/orderer/msp
      - ${CRYPTO_CONFIG_PATH}/ordererOrganizations/example.com/orderers/orderer.example.com/tls/:/var/hyperledger/orderer/tls
      - ${CHANNEL_ARTIFACTS_PATH}/genesis.block:/var/hyperledger/orderer/orderer.genesis.block
    ports:
      - "7050:7050"
    restart: always
    networks:
      - local
EOF


 mkdir -p docker-composes/database/
  cat > docker-composes/database/docker-compose-couchdb.yml << EOF
version: '3.4'

networks:
  local:
    name: fabric_local

services:
  couchdb.example.com:
    container_name: couchdb.example.com
    image: couchdb:3.1.0
    environment:
      - COUCHDB_USER=admin
      - COUCHDB_PASSWORD=adminpw
    ports:
      - "5984:5984"
    networks:
      - local
    volumes:
      - ./couchdb-data:/opt/couchdb/data
    restart: always
EOF

done