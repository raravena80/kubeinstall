#!/bin/bash

kubectl create -f https://k8s.io/examples/application/mysql/mysql-configmap.yaml
kubectl create -f https://k8s.io/examples/application/mysql/mysql-services.yaml
kubectl create -f https://k8s.io/examples/application/mysql/mysql-statefulset.yaml
