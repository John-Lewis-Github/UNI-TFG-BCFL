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
  rm -rf configtx.yaml channel-artifacts
  # Generar el archivo configtx.yaml
    echo "---
Organizations:" > configtx.yaml
    # Agregar perfil de organización para orderer
    echo "  - &OrdererOrg" >> $CONFIGTX_PATH
    echo "    Name: OrdererOrg" >> $CONFIGTX_PATH
    echo "    ID: OrdererMSP" >> $CONFIGTX_PATH
    echo "    MSPDir: crypto-config/ordererOrganizations/example.com/msp" >> $CONFIGTX_PATH
    echo "    Policies:" >> $CONFIGTX_PATH
    echo "      Readers:" >> $CONFIGTX_PATH
    echo "        Type: Signature" >> $CONFIGTX_PATH
    echo "        Rule: \"OR('OrdererMSP.member')\"" >> $CONFIGTX_PATH
    echo "      Writers:" >> $CONFIGTX_PATH
    echo "        Type: Signature" >> $CONFIGTX_PATH
    echo "        Rule: \"OR('OrdererMSP.member')\"" >> $CONFIGTX_PATH
    echo "      Admins:" >> $CONFIGTX_PATH
    echo "        Type: Signature" >> $CONFIGTX_PATH
    echo "        Rule: \"OR('OrdererMSP.admin')\"" >> $CONFIGTX_PATH

for org_name in "${org_names[@]}"; do
  org_prefix="${org_name%%.*}"
  org_prefix="${org_prefix^}"  # convierte la primera letra a mayúscula
  echo "  - &${org_prefix}MSP" >> "$CONFIGTX_PATH"
  echo "    Name: ${org_prefix}MSP" >> "$CONFIGTX_PATH"
  echo "    ID: ${org_prefix}MSP" >> "$CONFIGTX_PATH"
  echo "    MSPDir: crypto-config/peerOrganizations/${org_name}/msp" >> "$CONFIGTX_PATH"
  echo "    Policies:" >> "$CONFIGTX_PATH"
  echo "      Readers:" >> "$CONFIGTX_PATH"
  echo "        Type: Signature" >> "$CONFIGTX_PATH"
  echo "        Rule: \"OR('${org_prefix}MSP.admin', '${org_prefix}MSP.peer', '${org_prefix}MSP.client')\"" >> "$CONFIGTX_PATH"
  echo "      Writers:" >> "$CONFIGTX_PATH"
  echo "        Type: Signature" >> "$CONFIGTX_PATH"
  echo "        Rule: \"OR('${org_prefix}MSP.admin', '${org_prefix}MSP.client')\"" >> "$CONFIGTX_PATH"
  echo "      Admins:" >> "$CONFIGTX_PATH"
  echo "        Type: Signature" >> "$CONFIGTX_PATH"
  echo "        Rule: \"OR('${org_prefix}MSP.admin')\"" >> "$CONFIGTX_PATH"
  echo "      Endorsement:" >> "$CONFIGTX_PATH"
  echo "        Type: Signature" >> "$CONFIGTX_PATH"
  echo "        Rule: \"OR('${org_prefix}MSP.peer')\"" >> "$CONFIGTX_PATH"
  echo "    AnchorPeers:" >> "$CONFIGTX_PATH"
  echo "      - Host: peer0.${org_name}" >> "$CONFIGTX_PATH"
  echo "        Port: 7051" >> "$CONFIGTX_PATH"
done



    # Agregar sección de Capabilities
    echo "Capabilities:" >> $CONFIGTX_PATH
    echo "  Channel: &ChannelCapabilities" >> $CONFIGTX_PATH
    echo "    V2_0: true" >> $CONFIGTX_PATH
    echo "  Orderer: &OrdererCapabilities" >> $CONFIGTX_PATH
    echo "    V2_0: true" >> $CONFIGTX_PATH
    echo "  Application: &ApplicationCapabilities" >> $CONFIGTX_PATH
    echo "    V2_0: true" >> $CONFIGTX_PATH

    # Agregar sección de ApplicationDefaults
    echo "Application: &ApplicationDefaults" >> $CONFIGTX_PATH
    echo "  Organizations:" >> $CONFIGTX_PATH
    echo "  Policies:" >> $CONFIGTX_PATH
    echo "    Readers:" >> $CONFIGTX_PATH
    echo "      Type: ImplicitMeta" >> $CONFIGTX_PATH
    echo "      Rule: \"ANY Readers\"" >> $CONFIGTX_PATH
    echo "    Writers:" >> $CONFIGTX_PATH
    echo "      Type: ImplicitMeta" >> $CONFIGTX_PATH
    echo "      Rule: \"ANY Writers\"" >> $CONFIGTX_PATH
    echo "    Admins:" >> $CONFIGTX_PATH
    echo "      Type: ImplicitMeta" >> $CONFIGTX_PATH
    echo "      Rule: \"MAJORITY Admins\"" >> $CONFIGTX_PATH
    echo "    LifecycleEndorsement:" >> $CONFIGTX_PATH
    echo "      Type: ImplicitMeta" >> $CONFIGTX_PATH
    echo "      Rule: \"MAJORITY Endorsement\"" >> $CONFIGTX_PATH
    echo "    Endorsement:" >> $CONFIGTX_PATH
    echo "      Type: ImplicitMeta" >> $CONFIGTX_PATH
    echo "      Rule: \"MAJORITY Endorsement\"" >> $CONFIGTX_PATH
    echo "  Capabilities:" >> $CONFIGTX_PATH
    echo "    <<: *ApplicationCapabilities" >> $CONFIGTX_PATH
    # Agregar seccion ordererdefault
    cat <<EOF >> "$CONFIGTX_PATH"
Orderer: &OrdererDefaults
  OrdererType: etcdraft
  Addresses:
    - orderer.example.com:7050
  EtcdRaft:
    Consenters:
      - Host: orderer.example.com
        Port: 7050
        ClientTLSCert: ./crypto-config/ordererOrganizations/example.com/orderers/orderer.example.com/tls/server.crt
        ServerTLSCert: ./crypto-config/ordererOrganizations/example.com/orderers/orderer.example.com/tls/server.crt
  BatchTimeout: 2s
  BatchSize:
    MaxMessageCount: 10
    AbsoluteMaxBytes: 99 MB
    PreferredMaxBytes: 512 KB
  Organizations:
  Policies:
    Readers:
      Type: ImplicitMeta
      Rule: "ANY Readers"
    Writers:
      Type: ImplicitMeta
      Rule: "ANY Writers"
    Admins:
      Type: ImplicitMeta
      Rule: "MAJORITY Admins"
    BlockValidation:
      Type: ImplicitMeta
      Rule: "ANY Writers"
EOF

    # Agregar sección de ChannelDefaults
    echo "Channel: &ChannelDefaults"  >> $CONFIGTX_PATH
    echo "  Policies:" >> $CONFIGTX_PATH
    echo "    Readers:" >> $CONFIGTX_PATH
    echo "      Type: ImplicitMeta" >> $CONFIGTX_PATH
    echo "      Rule: \"ANY Readers\"" >> $CONFIGTX_PATH
    echo "    Writers:" >> $CONFIGTX_PATH
    echo "      Type: ImplicitMeta" >> $CONFIGTX_PATH
    echo "      Rule: \"ANY Writers\"" >> $CONFIGTX_PATH
    echo "    Admins:" >> $CONFIGTX_PATH
    echo "      Type: ImplicitMeta" >> $CONFIGTX_PATH
    echo "      Rule: \"MAJORITY Admins\"" >> $CONFIGTX_PATH
    echo "  Capabilities:" >> $CONFIGTX_PATH
    echo "    <<: *ChannelCapabilities" >> $CONFIGTX_PATH


    echo "Profiles:" >> "$CONFIGTX_PATH"
    echo "  OneOrgOrdererGenesis:" >> "$CONFIGTX_PATH"
    echo "    <<: *ChannelDefaults" >> "$CONFIGTX_PATH"
    echo "    Orderer:" >> "$CONFIGTX_PATH"
    echo "      <<: *OrdererDefaults" >> "$CONFIGTX_PATH"
    echo "      Organizations:" >> "$CONFIGTX_PATH"
    echo "        - *OrdererOrg" >> "$CONFIGTX_PATH"
    echo "      Capabilities:" >> "$CONFIGTX_PATH"
    echo "        <<: *OrdererCapabilities" >> "$CONFIGTX_PATH"
    echo "    Consortiums:" >> "$CONFIGTX_PATH"
    echo "      SampleConsortium:" >> "$CONFIGTX_PATH"
    echo "        Organizations:" >> "$CONFIGTX_PATH"

    for org_name in "${org_names[@]}"; do
      org_prefix="${org_name%%.*}"
      org_prefix="${org_prefix^}"  # convierte la primera letra a mayúscula
      echo "          - *${org_prefix}MSP" >> "$CONFIGTX_PATH"
    done

    echo "  MultiOrgChannel:" >> "$CONFIGTX_PATH"
    echo "    Consortium: SampleConsortium" >> "$CONFIGTX_PATH"
    echo "    <<: *ChannelDefaults" >> "$CONFIGTX_PATH"
    echo "    Application:" >> "$CONFIGTX_PATH"
    echo "      <<: *ApplicationDefaults" >> "$CONFIGTX_PATH"
    echo "      Organizations:" >> "$CONFIGTX_PATH"

    for org_name in "${org_names[@]}"; do
      org_prefix="${org_name%%.*}"
      org_prefix="${org_prefix^}"  # convierte la primera letra a mayúscula
      echo "        - *${org_prefix}MSP" >> "$CONFIGTX_PATH"
    done

    echo "      Capabilities:" >> "$CONFIGTX_PATH"
    echo "        <<: *ApplicationCapabilities" >> "$CONFIGTX_PATH"
    echo "" >> configtx.yaml
