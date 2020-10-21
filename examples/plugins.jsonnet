local grafana = import 'grafana/grafana.libsonnet';

{
  local basic =
    (grafana {
       _config+:: {
         namespace: 'monitoring-grafana',
         grafana+:: {
           plugins: ['camptocamp-prometheus-alertmanager-datasource'],
         },
       },
     }).grafana,

  apiVersion: 'v1',
  kind: 'List',
  items:
    basic.dashboardDefinitions +
    [
      basic.dashboardSources,
      basic.dashboardDatasources,
      basic.deployment,
      basic.serviceAccount,
      basic.service {
        spec+: { ports: [
          port {
            nodePort: 30910,
          }
          for port in super.ports
        ] },
      },
    ],
}
