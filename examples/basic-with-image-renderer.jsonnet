local grafana = import 'grafana/grafana.libsonnet';

local basicWithImageRenderer =
  (grafana {
     _config+:: {
       namespace: 'monitoring-grafana',
       versions+:: {
         grafanaImageRenderer: '1.0.9',
       },

       imageRepos+:: {
         grafanaImageRenderer: 'grafana/grafana-image-renderer',
       },

       grafana+:: {
         imageRendererPort: 8081,
         imageRendererContainer: {
           requests: { cpu: '100m', memory: '100Mi' },
           limits: { cpu: '200m', memory: '200Mi' },
         },

         env+: [
           { name: 'GF_RENDERING_SERVER_URL', value: 'http://localhost:' + $._config.grafana.imageRendererPort + '/render' },
           { name: 'GF_RENDERING_CALLBACK_URL', value: 'http://localhost:' + $._config.grafana.port },
         ],

         containers+: [
           {
             name: 'grafana-image-renderer',
             image: $._config.imageRepos.grafanaImageRenderer + ':' + $._config.versions.grafanaImageRenderer,
             ports: [{ name: 'http', containerPort: $._config.grafana.imageRendererPort }],
             resources: {
               requests: $._config.grafana.imageRendererContainer.requests,
               limits: $._config.grafana.imageRendererContainer.limits,
             },
           },
         ],
       },
     },
   }).grafana;

{
  apiVersion: 'v1',
  kind: 'List',
  items: [
    basicWithImageRenderer.dashboardSources,
    basicWithImageRenderer.dashboardDatasources,
    basicWithImageRenderer.deployment,
    basicWithImageRenderer.serviceAccount,
    basicWithImageRenderer.service {
      spec+: { ports: [
        port {
          nodePort: 30910,
        }
        for port in super.ports
      ] },
    },
  ],
}
