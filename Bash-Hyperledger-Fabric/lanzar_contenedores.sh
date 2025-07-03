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

  # Detener y eliminar todos los contenedores de Hyperledger Fabric en ejecución
  echo "Deteniendo y eliminando los contenedores de Hyperledger Fabric en ejecución..."
docker ps -a | grep hyperledger | awk '{print $1}' | xargs docker rm -f
docker ps -a | grep couchdb | awk '{print $1}' | xargs docker rm -f
docker container prune -f 
docker volume prune -f


  # Inicializar contador de intentos
  n=1
  max_attempts=2

  # Recorrer la carpeta docker-composes y lanzar todos los docker-compose
  find docker-composes -name "*.yml" | while read file
  do
    echo "Lanzando docker-compose de $file..."
    docker-compose -f "$file" up -d
  done

  # Comprobar si están todos los contenedores en ejecución
  failed_containers=()
  while [ $(docker ps -q | wc -l) -ne $(find docker-composes -name "*.yml" | wc -l) ] && [ $n -le $max_attempts ]
  do
  echo "Esperando a que se inicien todos los contenedores... Intento $n de $max_attempts"
    sleep 10
    ((n++))
    failed_containers=($(for file in $(find docker-composes -name "*.yml"); do basename "$file" .yml; done | grep -v $(docker ps --format '{{.Names}}') || true))
  done

# Mostrar información de contenedores no iniciados
if [ ${#failed_containers[@]} -gt 0 ]
then
  echo "Los siguientes contenedores no se han iniciado correctamente:"
  printf '%s\n' "${failed_containers[@]}"
  exit 1
fi