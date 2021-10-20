local kubernetesMixin = import 'github.com/kubernetes-monitoring/kubernetes-mixin/mixin.libsonnet';
local grafana = import 'grafana/grafana.libsonnet';

{
  _config:: {
    namespace: 'monitoring-grafana',
    dashboards: kubernetesMixin.grafanaDashboards,
  },

  grafana: grafana($._config) + {
    service+: {
      spec+: {
        ports: [
          port {
            nodePort: 30910,
          }
          for port in super.ports
        ],
      },
    },
  },
}
