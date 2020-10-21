local grafana = import 'github.com/grafana/grafonnet-lib/grafonnet/grafana.libsonnet';
local dashboard = grafana.dashboard;
local row = grafana.row;
local prometheus = grafana.prometheus;
local template = grafana.template;
local graphPanel = grafana.graphPanel;

local grafana = import 'grafana/grafana.libsonnet';

local grafanaWithDashboards =
  (grafana
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
               .addPanel(
                 graphPanel.new('My Panel', span=6, datasource='$datasource')
                 .addTarget(prometheus.target('vector(1)')),
               )
             ),
         },
       },
     },
   }).grafana;

{
  apiVersion: 'v1',
  kind: 'List',
  items:
    grafanaWithDashboards.dashboardDefinitions +
    [
      grafanaWithDashboards.dashboardSources,
      grafanaWithDashboards.dashboardDatasources,
      grafanaWithDashboards.deployment,
      grafanaWithDashboards.serviceAccount,
      grafanaWithDashboards.service {
        spec+: { ports: [
          port {
            nodePort: 30910,
          }
          for port in super.ports
        ] },
      },
    ],
}
