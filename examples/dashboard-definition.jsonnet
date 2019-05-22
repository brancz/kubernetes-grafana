local k = import 'ksonnet/ksonnet.beta.3/k.libsonnet';
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
         dashboards+:: {
           'my-dashboard.json':
             dashboard.new('My Dashboard')
             .addTemplate(
               {
                 current: {
                   text: 'Prometheus',
                   value: 'Prometheus',
                 },
                 hide: 0,
                 label: null,
                 name: 'datasource',
                 options: [],
                 query: 'prometheus',
                 refresh: 1,
                 regex: '',
                 type: 'datasource',
               },
             )
             .addRow(
               row.new()
               .addPanel(graphPanel.new('My Panel', span=6, datasource='$datasource')
                         .addTarget(prometheus.target('vector(1)')))
             ),
         },
       },
     },
   }).grafana;

k.core.v1.list.new(
  [
    grafana.dashboardDefinitions,
    grafana.dashboardSources,
    grafana.dashboardDatasources,
    grafana.deployment,
    grafana.serviceAccount,
    grafana.service +
    service.mixin.spec.withPorts(servicePort.newNamed('http', 3000, 'http') + servicePort.withNodePort(30910)) +
    service.mixin.spec.withType('NodePort'),
  ]
)
