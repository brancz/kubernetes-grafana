local grafana = import 'grafana/grafana.libsonnet';

local imageRenderer = {
  name: 'grafana-image-renderer',
  image: 'grafana/grafana-image-renderer:1.0.9',
  ports: [{ name: 'http', containerPort: 8081 }],
  resources: {
    requests: { cpu: '100m', memory: '100Mi' },
    limits: { cpu: '200m', memory: '200Mi' },
  },
};

{
  _config:: {
    namespace: 'monitoring-grafana',
    env: [
      { name: 'GF_RENDERING_SERVER_URL', value: 'http://localhost:' + imageRenderer.ports[0].containerPort + '/render' },
      { name: 'GF_RENDERING_CALLBACK_URL', value: 'http://localhost:' + $.grafana._config.port },
    ],
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
