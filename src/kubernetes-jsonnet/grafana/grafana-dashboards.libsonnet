local k = import "ksonnet.beta.3/k.libsonnet";
local configMap = k.core.v1.configMap;

local dashboardSources = import "configs/dashboard-sources/dashboards.libsonnet";

{
    new(namespace)::
        configMap.new("grafana-dashboards", {"dashboards.yaml": std.manifestJsonEx(dashboardSources, "    ")}) +
          configMap.mixin.metadata.withNamespace(namespace)
}
