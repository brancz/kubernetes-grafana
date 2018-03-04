local k = import "ksonnet.beta.3/k.libsonnet";
local service = k.core.v1.service;
local servicePort = k.core.v1.service.mixin.spec.portsType;

local grafanaDeployment = import "grafana-deployment.jsonnet";

local grafanaServiceNodePort = servicePort.newNamed("http", 3000, "http") +
    servicePort.withNodePort(0);

service.new("grafana", grafanaDeployment.spec.selector.matchLabels, grafanaServiceNodePort) +
    service.mixin.spec.withType("NodePort")
