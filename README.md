# UNI-TFG-BCFL
Código del TFG para despliegue de blockchain de Hyperledger Fabric para compartición y actualización segura de modelos de aprendizaje federado (FL)

## Estructura
El código se organiza en 4 carpetas.
- **Flower**. Para el código en Python que permite desplegar el entorno FL de Flower.
- **Bash-Hyperledger-Fabric**. Para los scripts de bash que lanzan la blockchain de Hyperledger Fabric
- **chaincode**. Para el código de Java del smart contract utilizado
- **ChainREST**. Para el código en Node.js de la API REST utilizada

## Indicaciones
### Flower
En esta carpeta se encuentra el código que hemos hecho dentro de la subcarpeta **bcfl**. Para probarlo en local se recomienda instalar un entorno virtual .venv con python3.11 y, utilizando el binario de pip de dicho entorno virtual, descarga Flower:
``` pip install  flwr[simulation]```
```cd ./bcfl```
```pip install -e .```
```flwr run .```
Asimismo, para alguna de las gráficas que resultan, se necesita incluir las modificaciones del código server.py, que se encuentra dentor de la librería de flwr.

### Hyperledger Bash
Ejecútalo en el siguiente orden
1. _
