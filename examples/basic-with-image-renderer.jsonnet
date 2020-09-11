local k = import 'github.com/ksonnet/ksonnet-lib/ksonnet.beta.4/k.libsonnet';
local container = k.apps.v1.deployment.mixin.spec.template.spec.containersType;
local env = container.envType;
local containerPort = container.portsType;
local service = k.core.v1.service;
local servicePort = k.core.v1.service.mixin.spec.portsType;

local grafana = ((import 'grafana/grafana.libsonnet') + {
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
                         env.new('GF_RENDERING_SERVER_URL', 'http://localhost:' + $._config.grafana.imageRendererPort + '/render'),
                         env.new('GF_RENDERING_CALLBACK_URL', 'http://localhost:' + $._config.grafana.port),
                       ],

                       containers+: [
                         local volume = k.apps.v1.deployment.mixin.spec.template.spec.volumesType;
                           container.new('grafana-image-renderer', $._config.imageRepos.grafanaImageRenderer + ':' + $._config.versions.grafanaImageRenderer) +
                           container.withPorts(containerPort.newNamed($._config.grafana.imageRendererPort, 'http')) +
                           container.mixin.resources.withRequests($._config.grafana.imageRendererContainer.requests) +
                           container.mixin.resources.withLimits($._config.grafana.imageRendererContainer.limits),
                       ],
                     },
                   },
                 }).grafana;

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
