local k = import "ksonnet.beta.3/k.libsonnet";
local configMap = k.core.v1.configMap;

local dashboards = {
    "deployments-dashboard.json": import "configs/dashboard-definitions/deployments-dashboard.libsonnet",
    "kubernetes-capacity-planning-dashboard.json": import "configs/dashboard-definitions/kubernetes-capacity-planning-dashboard.libsonnet",
    "kubernetes-cluster-health-dashboard.json": import "configs/dashboard-definitions/kubernetes-cluster-health-dashboard.libsonnet",
    "kubernetes-cluster-status-dashboard.json": import "configs/dashboard-definitions/kubernetes-cluster-status-dashboard.libsonnet",
    "kubernetes-kubelet-dashboard.json": import "configs/dashboard-definitions/kubernetes-kubelet-dashboard.libsonnet",
    "nodes.json": import "configs/dashboard-definitions/nodes.libsonnet",
    "pods-dashboard.json": import "configs/dashboard-definitions/pods-dashboard.libsonnet",
};

{
    new(namespace)::
        configMap.new("grafana-dashboard-definitions", {[name]: std.manifestJsonEx(dashboards[name], "    ") for name in std.objectFields(dashboards)}) +
          configMap.mixin.metadata.withNamespace(namespace)
}
