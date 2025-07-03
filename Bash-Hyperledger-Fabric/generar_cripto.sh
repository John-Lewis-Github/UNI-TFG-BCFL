#!/bin/bash
declare -a org_names=()
org_names+=("org1.example.com")
org_names+=("org2.example.com")

rm -rf crypto-config
  # Crear el archivo de configuración crypto-config.yaml
  echo "OrdererOrgs:" > crypto-config.yaml
  echo "  - Name: Orderer" >> crypto-config.yaml
  echo "    Domain: example.com" >> crypto-config.yaml
  echo "    Specs:" >> crypto-config.yaml
  echo "      - Hostname: orderer" >> crypto-config.yaml
  echo "        SANS:" >> crypto-config.yaml
  echo "          - \"localhost\"" >> crypto-config.yaml
  echo "          - \"127.0.0.1\"" >> crypto-config.yaml
  echo "          - \"orderer.example.com\"" >> crypto-config.yaml
  echo "" >> crypto-config.yaml
  echo "PeerOrgs:" >> crypto-config.yaml
  for org_name in "${org_names[@]}"; do
    echo "  - Name: ${org_prefix}" >> crypto-config.yaml
    echo "    Domain: $org_name" >> crypto-config.yaml
    echo "    EnableNodeOUs: true" >> crypto-config.yaml
    echo "    Specs:" >> crypto-config.yaml
    echo "      - Hostname: peer0" >> crypto-config.yaml
    echo "        SANS:" >> crypto-config.yaml
    echo "          - 'peer0.${org_name}'" >> crypto-config.yaml
    echo "          - 'peer0'" >> crypto-config.yaml
    echo "          - 'localhost'" >> crypto-config.yaml
    echo "          - '127.0.0.1'" >> crypto-config.yaml
    echo "    Template:" >> crypto-config.yaml
    echo "      Count: 1" >> crypto-config.yaml
    echo "    Users:" >> crypto-config.yaml
    echo "      Count: 1" >> crypto-config.yaml
  done

  # Crear la carpeta crypto-config/ordererOrganizations
  mkdir -p crypto-config/ordererOrganizations/example.com

  # Generar la criptografía para las organizaciones y el nodo ordenador
  cryptogen generate --config=crypto-config.yaml --output=crypto-config
