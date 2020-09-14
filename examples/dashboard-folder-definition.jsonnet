local k = import 'github.com/ksonnet/ksonnet-lib/ksonnet.beta.4/k.libsonnet';
local service = k.core.v1.service;
local servicePort = k.core.v1.service.mixin.spec.portsType;

local grafana = import 'grafonnet/grafana.libsonnet';
local dashboard = grafana.dashboard;
local row = grafana.row;
local prometheus = grafana.prometheus;
local template = grafana.template;
local graphPanel = grafana.graphPanel;

local grafana =
  ((import 'grafana/grafana.libsonnet') +
   {
     _config+:: {
       namespace: 'monitoring-grafana',
       grafana+:: {
         folderDashboards+:: {
           Services: {
             'regional-services-dashboard.json': (import 'dashboards/regional-services-dashboard.json'),
             'global-services-dashboard.json': (import 'dashboards/global-services-dashboard.json'),
           },
           AWS: {
             'aws-ec2-dashboard.json': (import 'dashboards/aws-ec2-dashboard.json'),
             'aws-rds-dashboard.json': (import 'dashboards/aws-rds-dashboard.json'),
             'aws-sqs-dashboard.json': (import 'dashboards/aws-sqs-dashboard.json'),
           },
           ISTIO: {
             'istio-citadel-dashboard.json': (import 'dashboards/istio-citadel-dashboard.json'),
             'istio-galley-dashboard.json': (import 'dashboards/istio-galley-dashboard.json'),
             'istio-mesh-dashboard.json': (import 'dashboards/istio-mesh-dashboard.json'),
             'istio-pilot-dashboard.json': (import 'dashboards/istio-pilot-dashboard.json'),
           }
         },
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
