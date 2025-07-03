"""BCFL: A Flower / PyTorch app."""

import decimal
import json
import os
import random
import time
import requests
import torch

from flwr.client import ClientApp, NumPyClient
from flwr.common import Context
from bcfl.task import Net, TensorEncoder, get_weights, load_data, set_weights, test, train


# Define Flower Client and client_fn
class FlowerClient(NumPyClient):
    def __init__(self, net, trainloader, valloader, local_epochs, context: Context):
        self.nclient = context.node_config['partition-id']
        self.run_config = context.run_config
        self.maliciosos = [4, 8]
        self.net = net
        self.trainloader = trainloader
        self.valloader = valloader
        self.local_epochs = local_epochs
        self.device = torch.device("cuda:0" if torch.cuda.is_available() else "cpu")
        self.net.to(self.device)

    def fit(self, parameters, config):
        if self.nclient not in self.maliciosos:
            set_weights(self.net, parameters)
            train_loss = train(
                self.net,
                self.trainloader,
                self.local_epochs,
                config['lr'],
                self.device,
            )
        else: 
            self.net = Net()
            train_loss = float(decimal.Decimal(random.randrange(10559537954701993, 13917421226781840))/100000000000000000)
        # Cada cliente espera un intervalo de tiempo distinto para que 
        # el servidor donde esta alojada la blockchain no nos corte
        # la conexion
        time.sleep(self.nclient*2)
        print(self.nclient)
        estado_modelo_global = self.net.state_dict()
        url = "http://155.54.95.237:3000/chain/json"
        headers = {"Content-Type": "application/json"}
        payload = {
            "id": f"cliente{self.nclient}_{config['round']}",
            "data": json.dumps({
                "conv1.weight": estado_modelo_global['conv1.weight'],
                "conv1.bias": estado_modelo_global['conv1.bias'],
                "conv2.weight": estado_modelo_global['conv2.weight'],
                "conv2.bias": estado_modelo_global['conv2.bias'],
                "fc1.weight": estado_modelo_global['fc1.weight'],
                "fc1.bias": estado_modelo_global['fc1.bias'],
                "fc2.weight": estado_modelo_global['fc2.weight'],
                "fc2.bias": estado_modelo_global['fc2.bias'],
                "fc3.weight": estado_modelo_global['fc3.weight'],
                "fc3.bias": estado_modelo_global['fc3.bias']   
            }, cls=TensorEncoder)
        }
        r = requests.post(url, headers=headers, json=payload)
        
        base_path = os.path.dirname(os.path.abspath(__file__))
        file_name = "/ronda" + str(config['round']) ## your path variable
        file_path = base_path + file_name
        with open(file_path, "a") as myfile:
            myfile.write(str(self.nclient) + "\n")
        #config['round']
        return (
            get_weights(self.net),
            len(self.trainloader.dataset),
            {"train_loss": train_loss},
        )

    def evaluate(self, parameters, config):
        if self.nclient not in self.maliciosos:
            set_weights(self.net, parameters)
            loss, accuracy = test(self.net, self.valloader, self.device)
        else:
            loss = float(decimal.Decimal(random.randrange(10559537954701993, 13917421226781840))/100000000000000000)
            accuracy = float(decimal.Decimal(random.randrange(9055953795470191, 9691742122678180))/10000000000000000)
        
        
        return loss, len(self.valloader.dataset), {"accuracy": accuracy}


def client_fn(context: Context):
    # Load model and data
    net = Net()
    partition_id = context.node_config["partition-id"]
    num_partitions = context.node_config["num-partitions"]
    trainloader, valloader = load_data(partition_id, num_partitions)
    local_epochs = context.run_config["local-epochs"]

    # Return Client instance
    return FlowerClient(net, trainloader, valloader, local_epochs, context).to_client()


# Flower ClientApp
app = ClientApp(
    client_fn,
)
