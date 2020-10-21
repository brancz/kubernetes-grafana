local kubernetesMixin = import 'github.com/kubernetes-monitoring/kubernetes-mixin/mixin.libsonnet';
local grafana = import 'grafana/grafana.libsonnet';

{
  local basicWithMixin =
    (grafana {
       _config+:: {
         namespace: 'monitoring-grafana',
         grafana+:: {
           dashboards: kubernetesMixin.grafanaDashboards,
         },
       },
     }).grafana,

  apiVersion: 'v1',
  kind: 'List',
  items:
    basicWithMixin.dashboardDefinitions +
    [
      basicWithMixin.dashboardSources,
      basicWithMixin.dashboardDatasources,
      basicWithMixin.deployment,
      basicWithMixin.serviceAccount,
      basicWithMixin.service {
        spec+: { ports: [
          port {
            nodePort: 30910,
          }
          for port in super.ports
        ] },
      },
    ],
}
