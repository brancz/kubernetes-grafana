local grafana = import 'grafana/grafana.libsonnet';

{
  local customIni =
    grafana({
      _config+:: {
        namespace: 'monitoring-grafana',
        grafana+:: {
          config: {
            sections: {
              metrics: { enabled: true },
              'auth.ldap': {
                enabled: true,
                config_file: '/etc/grafana/ldap.toml',
                allow_sign_up: true,
              },
            },
          },
          ldap: |||
            [[servers]]
            host = "127.0.0.1"
            port = 389
            use_ssl = false
            start_tls = false
            ssl_skip_verify = false

            bind_dn = "cn=admin,dc=grafana,dc=org"
            bind_password = 'grafana'

            search_filter = "(cn=%s)"

            search_base_dns = ["dc=grafana,dc=org"]
          |||,
        },
      },
    }),

  apiVersion: 'v1',
  kind: 'List',
  items:
    customIni.dashboardDefinitions.items +
    [
      customIni.config,
      customIni.dashboardSources,
      customIni.dashboardDatasources,
      customIni.deployment,
      customIni.serviceAccount,
      customIni.service {
        spec+: { ports: [
          port {
            nodePort: 30910,
          }
          for port in super.ports
        ] },
      },
    ],
}
