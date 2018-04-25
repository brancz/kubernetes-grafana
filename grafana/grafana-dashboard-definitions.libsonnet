local k = import "ksonnet/ksonnet.beta.3/k.libsonnet";
local configMap = k.core.v1.configMap;

{
    dashboardDefinitions:
        configMap.new("grafana-dashboard-definitions", {[name]: std.manifestJsonEx($._config.dashboards[name], "    ") for name in std.objectFields($._config.dashboards)}) +
          configMap.mixin.metadata.withNamespace($._config.namespace)
}
