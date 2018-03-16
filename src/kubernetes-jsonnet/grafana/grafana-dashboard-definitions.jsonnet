local k = import "ksonnet.beta.3/k.libsonnet";
local configMap = k.core.v1.configMap;

local dashboards = {
    "deployments-dashboard.json": import "configs/dashboard-definitions/deployments-dashboard.jsonnet",
    "kubernetes-capacity-planning-dashboard.json": import "configs/dashboard-definitions/kubernetes-capacity-planning-dashboard.jsonnet",
    "kubernetes-cluster-health-dashboard.json": import "configs/dashboard-definitions/kubernetes-cluster-health-dashboard.jsonnet",
    "kubernetes-cluster-status-dashboard.json": import "configs/dashboard-definitions/kubernetes-cluster-status-dashboard.jsonnet",
    "kubernetes-kubelet-dashboard.json": import "configs/dashboard-definitions/kubernetes-kubelet-dashboard.jsonnet",
    "nodes.json": import "configs/dashboard-definitions/nodes.jsonnet",
    "pods-dashboard.json": import "configs/dashboard-definitions/pods-dashboard.jsonnet",
};

configMap.new("grafana-dashboard-definitions", {[name]: std.manifestJsonEx(dashboards[name], "    ") for name in std.objectFields(dashboards)})
