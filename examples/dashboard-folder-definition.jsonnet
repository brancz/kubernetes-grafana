local grafonnet = import 'github.com/grafana/grafonnet-lib/grafonnet/grafana.libsonnet';
local dashboard = grafonnet.dashboard;
local row = grafonnet.row;
local prometheus = grafonnet.prometheus;
local template = grafonnet.template;
local graphPanel = grafonnet.graphPanel;

local grafana = import 'grafana/grafana.libsonnet';

{
  _config:: {
    namespace: 'monitoring-grafana',
    folderDashboards+: {
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
