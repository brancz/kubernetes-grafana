local k = import "ksonnet/ksonnet.beta.3/k.libsonnet";
local service = k.core.v1.service;
local servicePort = k.core.v1.service.mixin.spec.portsType;

local kubernetes_mixin = import "kubernetes-mixin/mixin.libsonnet";

local grafana = (import "grafana/grafana.libsonnet") + {
    _config+:: {
        namespace: "monitoring-grafana",
        dashboards: kubernetes_mixin.grafana_dashboards,
    }
};

k.core.v1.list.new([
    grafana.dashboardDefinitions,
    grafana.dashboardSources,
    grafana.dashboardDatasources,
    grafana.deployment,
    grafana.serviceAccount,
    grafana.service +
        service.mixin.spec.withPorts(servicePort.newNamed("http", 3000, "http") + servicePort.withNodePort(30910)) +
        service.mixin.spec.withType("NodePort"),
])
