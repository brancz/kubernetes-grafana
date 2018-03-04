#!/usr/bin/env sh

./build.sh
echo -e "\033[1m>> Deleting Grafana stack (it's ok if this fails if you haven't deployed this previously)\033[0m"
kubectl delete -f artifacts/grafana.yaml
echo -e "\033[1m>> Creating Grafana stack\033[0m"
kubectl create -f artifacts/grafana.yaml
echo -e "\033[1m>> Opening Grafana in your browser when it's ready\033[0m"
minikube service grafana
