local k = import 'github.com/ksonnet/ksonnet-lib/ksonnet.beta.4/k.libsonnet';
local service = k.core.v1.service;
local servicePort = k.core.v1.service.mixin.spec.portsType;

local grafana = ((import 'grafana/grafana.libsonnet') + {
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
                 }).grafana;

k.core.v1.list.new(
  grafana.dashboardDefinitions +
  [
    grafana.config,
    grafana.dashboardSources,
    grafana.dashboardDatasources,
    grafana.deployment,
    grafana.serviceAccount,
    grafana.service +
    service.mixin.spec.withPorts(servicePort.newNamed('http', 3000, 'http') + servicePort.withNodePort(30910)) +
    service.mixin.spec.withType('NodePort'),
  ]
)
