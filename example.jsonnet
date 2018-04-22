local k = import "ksonnet.beta.3/k.libsonnet";
local service = k.core.v1.service;
local servicePort = k.core.v1.service.mixin.spec.portsType;
local grafana = import "grafana/grafana.libsonnet";
local namespace = "monitoring-grafana";

k.core.v1.list.new([
    grafana.dashboardDefinitions.new(namespace),
    grafana.dashboardSources.new(namespace),
    grafana.dashboardDatasources.new(namespace),
    grafana.deployment.new(namespace),
    grafana.serviceAccount.new(namespace),
    grafana.service.new(namespace) +
        service.mixin.spec.withPorts(servicePort.newNamed("http", 3000, "http") + servicePort.withNodePort(30910)) +
        service.mixin.spec.withType("NodePort"),
])
