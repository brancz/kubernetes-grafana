local k = import "ksonnet.beta.3/k.libsonnet";
local configMap = k.core.v1.configMap;

local prometheusDatasource = import "configs/datasources/prometheus.libsonnet";

{
    new(namespace)::
        configMap.new("grafana-datasources", {"prometheus.yaml": std.manifestJsonEx(prometheusDatasource, "    ")}) +
          configMap.mixin.metadata.withNamespace(namespace)
}
