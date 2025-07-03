import os
from matplotlib import pyplot as plt
import requests
import json
from types import SimpleNamespace

from datasets import load_dataset, Split
from task import Net, TensorEncoder, get_transforms, get_weights, set_weights, test
from flwr.common import  ndarrays_to_parameters
from torch.utils.data import DataLoader
import torch
import torch.nn as nn
import torch.nn.functional as F

round = 7
accuracies = [0.0, 0.0, 0.0, 0.0, 0.0]
clientes = [2, 3, 5, 12, 16]
i = 0
for ncliente in clientes: # Para cada cliente
    # Descargamos su modelo local grabado en la blockchain
    print(f"Cliente {ncliente}")
    objectID = f"cliente{ncliente}_{round}"
    url = f"http://155.54.95.237:3000/chain/json?id={objectID}"
    data = requests.get(url)
    # Transformamos la cadena obtenida en un diccionario de strings y tensores de Pytorch
    resp = data.text
    desempaquetado = json.loads(json.loads(json.loads(resp)[f"{objectID}"])['data'])
    for idx in desempaquetado:
        desempaquetado[idx] = torch.tensor(desempaquetado[idx])
    # Tras esto recreamos el modelo original
    weights = [val.cpu().numpy() for _, val in desempaquetado.items()]
    net = Net()
    set_weights(net, weights)
    # y lo testeamos frente al modelo de MNIST utilizado
    device = torch.device("cuda:0" if torch.cuda.is_available() else "cpu")
    net.to(device)
    testset = load_dataset("ylecun/mnist",split=Split.TEST)
    testloader = DataLoader(testset.with_transform(get_transforms()), batch_size=32)
    loss, accuracy = test(net, testloader, device)
    accuracies[i] = accuracy*100
    i=i+1
clientes = [f"cliente {n}" for n in clientes]

plt.bar(clientes, accuracies, color='red')
plt.title(f"Accuracy de cada modelo local agregado en la ronda {round}")
plt.xlabel(f"Clientes que han sido elegidos para la ronda {round}")
plt.ylabel('Accuracy (%)')
base_path = os.path.dirname(os.path.abspath(__file__))
file_name = f"/accuracyModelosLocalesRonda{round}.png" ## your path variable
file_path = base_path + file_name
if os.path.exists(file_path):
        os.remove(file_path)
plt.savefig(file_path)


