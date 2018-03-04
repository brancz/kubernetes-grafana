local k = import "ksonnet.beta.3/k.libsonnet";

k.core.v1.list.new([
    import "grafana-dashboard-definitions.jsonnet",
    import "grafana-dashboards.jsonnet",
    import "grafana-datasources.jsonnet",
    import "grafana-deployment.jsonnet",
    import "grafana-service-account.jsonnet",
    import "grafana-service.jsonnet",
])
