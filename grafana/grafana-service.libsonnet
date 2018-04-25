local k = import "ksonnet/ksonnet.beta.3/k.libsonnet";
local service = k.core.v1.service;
local servicePort = k.core.v1.service.mixin.spec.portsType;

{
    service:
        local grafanaServiceNodePort = servicePort.newNamed("http", 3000, "http");

        service.new("grafana", $.deployment.spec.selector.matchLabels, grafanaServiceNodePort) +
          service.mixin.metadata.withNamespace($._config.namespace)
}
