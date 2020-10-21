local grafana = import 'grafonnet/grafana.libsonnet';
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
           },
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
