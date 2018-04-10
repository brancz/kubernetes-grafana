local k = import "ksonnet.beta.3/k.libsonnet";
local service = k.core.v1.service;
local servicePort = k.core.v1.service.mixin.spec.portsType;

local grafanaDeployment = import "grafana-deployment.libsonnet";

local grafanaServiceNodePort = servicePort.newNamed("http", 3000, "http");

{
    new(namespace)::
        service.new("grafana", grafanaDeployment.new(namespace).spec.selector.matchLabels, grafanaServiceNodePort) +
          service.mixin.metadata.withNamespace(namespace)
}
