"""BCFL: A Flower / PyTorch app."""

import codecs
import json
import os
import time
from typing import List, Tuple
from flwr.common import Context, ndarrays_to_parameters, Metrics
from flwr.server import ServerApp, ServerAppComponents, ServerConfig
from flwr.server.strategy import FedAvg
from bcfl.task import Net, TensorEncoder, get_json_weights, get_weights, set_weights, test, get_transforms
from datasets import load_dataset, Split
import requests
import torch
from torch.utils.data import DataLoader


def get_evaluate_fn(testloader, device):  
    """Funcion para evaluar el modelo global"""
    def evaluate(server_round, parameters_ndarrays, config):
        net = Net()
        set_weights(net, parameters_ndarrays)
        net.to(device)
        loss, accuracy = test(net, testloader, device)
        if server_round > 0:
            url = "http://155.54.95.237:3000/chain/json"
            headers = {"Content-Type": "application/json"}
            payload = {
                "id": f"global{server_round}_metricas",
                "data": json.dumps({
                    "loss": loss,
                    "accuracy": accuracy
                })
            }
            r = requests.post(url, headers=headers, json=payload)
            #url = f"http://155.54.95.237:3000/chain/json?id=global{server_round}_metricas"
            #data = requests.get(url)
            #print(data.text)
            #print(r.text)
            print("Esperamos 3 segundos tras subir las metricas")
            time.sleep(3)
            
            estado_modelo_global = net.state_dict()

            payload = {
                "id": f"global{server_round}",
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
            #print(r.text)
            
            print("Esperamos 5 segundos tras subir los pesos globales")
            time.sleep(4)
        
        return loss, {"cen_accuracy": accuracy}
    return evaluate

def weighted_average(metrics: List[Tuple[int, Metrics]]) -> Metrics:
    """Funcion para agregar metricas"""
    accuracies = [num_examples * m["accuracy"] for num_examples, m in metrics]
    total_examples = sum(num_examples for num_examples, _ in metrics)
    
    return {"accuracy": sum(accuracies)/total_examples}

def on_fit_config(server_round: int) -> Metrics:
    """Funcion para modificar parametros de configuracion"""
    lr = 0.01
    if server_round > 2:
        lr = 0.01
    return {"lr": lr, "round": server_round}

def on_evaluate_config(server_round: int) -> Metrics:
    """Funcion para modificar parametros de evaluacion"""
    return {"round": server_round}


def server_fn(context: Context):
    # Read from config
    num_rounds = context.run_config["num-server-rounds"]
    print(f"num_rounds={num_rounds}")
    for i in range(1,num_rounds+1):
        print(i)
    fraction_fit = context.run_config["fraction-fit"]

    # Initialize model parameters
    modelo_global = Net()
    ndarrays = get_weights(modelo_global) # array numpy
    parameters = ndarrays_to_parameters(ndarrays)
    
          
    print("Eliminamos ficheros guardados con anterioridad")
    base_path = os.path.dirname(os.path.abspath(__file__))
    for i in range(1,num_rounds+1):
        file_name = "/ronda" + str(i) ## your path variable
        file_path = base_path + file_name
        if os.path.exists(file_path):
            os.remove(file_path)
    
    
    # Cargar test set global
    testset = load_dataset("ylecun/mnist",split=Split.TEST)
    testloader = DataLoader(testset.with_transform(get_transforms()), batch_size=32)
    device = torch.device("cuda:0" if torch.cuda.is_available() else "cpu")

    # Define strategy
    strategy = FedAvg(
        fraction_fit=fraction_fit,
        fraction_evaluate=1.0,
        min_available_clients=2,
        initial_parameters=parameters,
        evaluate_metrics_aggregation_fn=weighted_average,
        on_fit_config_fn=on_fit_config,
        on_evaluate_config_fn=on_evaluate_config,
        evaluate_fn=get_evaluate_fn(testloader, device)
    )
    config = ServerConfig(num_rounds=num_rounds)
    
    return ServerAppComponents(strategy=strategy, config=config)


# Create ServerApp
app = ServerApp(server_fn=server_fn)
