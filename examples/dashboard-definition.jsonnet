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
    dashboards+: {
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
