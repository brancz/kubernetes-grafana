local grafana = import 'grafana/grafana.libsonnet';

{
  _config:: {
    namespace: 'monitoring-grafana',
    notifiers+: [
                  {
                    "name": "example-alert-emails",
                    "type": "email",
                    "org_name": "Example",
                    "frequency": "1h",
                    "uid" : "mailnotifier",
                    "is_default": true,
                    "settings":{
                      "addresses": "example@grafana.com"
                    }
                  }
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
