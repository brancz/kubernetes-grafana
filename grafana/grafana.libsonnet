{
    _config+:: {
        namespace: "default",
        dashboards: {},
    }
} +
(import "grafana-dashboard-definitions.libsonnet") +
(import "grafana-dashboards.libsonnet") +
(import "grafana-datasources.libsonnet") +
(import "grafana-deployment.libsonnet") +
(import "grafana-service-account.libsonnet") +
(import "grafana-service.libsonnet")
