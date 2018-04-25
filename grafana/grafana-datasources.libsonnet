local k = import "ksonnet/ksonnet.beta.3/k.libsonnet";
local configMap = k.core.v1.configMap;

local prometheusDatasource = import "configs/datasources/prometheus.libsonnet";

{
    dashboardDatasources:
        configMap.new("grafana-datasources", {"prometheus.yaml": std.manifestJsonEx(prometheusDatasource, "    ")}) +
          configMap.mixin.metadata.withNamespace($._config.namespace)
}
