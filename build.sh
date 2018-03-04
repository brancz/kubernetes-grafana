#!/usr/bin/env sh

echo -e "\033[1m>> Generating Kubernetes manifests for Grafana\033[0m"
docker build -t quay.io/brancz/kubernetes-grafana .
docker run --rm -u=$UID:$(id -g $USER) -it -v `pwd`:/go/src/github.com/brancz/kubernetes-grafana quay.io/brancz/kubernetes-grafana /bin/sh -c "rm -rf artifacts; mkdir artifacts; jsonnet -J /go/src/github.com/ksonnet/ksonnet-lib -J /go/src/github.com/grafana/grafonnet-lib src/kubernetes-jsonnet/grafana/grafana.jsonnet | gojsontoyaml > artifacts/grafana.yaml"
