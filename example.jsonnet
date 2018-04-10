local k = import "ksonnet.beta.3/k.libsonnet";
local grafana = import "grafana/grafana.libsonnet";
local namespace = "monitoring";

k.core.v1.list.new([
    grafana.dashboardDefinitions.new(namespace),
    grafana.dashboardSources.new(namespace),
    grafana.dashboardDatasources.new(namespace),
    grafana.deployment.new(namespace),
    grafana.serviceAccount.new(namespace),
    grafana.service.new(namespace),
])
