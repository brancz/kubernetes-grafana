{
    dashboardDefinitions:: import "grafana-dashboard-definitions.libsonnet",
    dashboardSources:: import "grafana-dashboards.libsonnet",
    dashboardDatasources:: import "grafana-datasources.libsonnet",
    deployment:: import "grafana-deployment.libsonnet",
    serviceAccount:: import "grafana-service-account.libsonnet",
    service:: import "grafana-service.libsonnet",
}
