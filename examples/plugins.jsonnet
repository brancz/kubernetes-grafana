local grafana = import 'grafana/grafana.libsonnet';

{
  _config:: {
    namespace: 'monitoring-grafana',
    plugins: ['camptocamp-prometheus-alertmanager-datasource'],
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
