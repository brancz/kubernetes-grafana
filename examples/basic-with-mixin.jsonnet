local k = import 'github.com/ksonnet/ksonnet-lib/ksonnet.beta.4/k.libsonnet';
local service = k.core.v1.service;
local servicePort = k.core.v1.service.mixin.spec.portsType;

local grafana = (
  (import 'grafana/grafana.libsonnet') +
  (import 'kubernetes-mixin/mixin.libsonnet') +
  {
    _config+:: {
      namespace: 'monitoring-grafana',
      grafana+:: {
        dashboards: $.grafanaDashboards,
      },
    },
  }
).grafana;

k.core.v1.list.new(
  grafana.dashboardDefinitions +
  [
    grafana.dashboardSources,
    grafana.dashboardDatasources,
    grafana.deployment,
    grafana.serviceAccount,
    grafana.service +
    service.mixin.spec.withPorts(servicePort.newNamed('http', 3000, 'http') + servicePort.withNodePort(30910)) +
    service.mixin.spec.withType('NodePort'),
  ]
)
