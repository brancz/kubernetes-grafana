local grafana = import "grafonnet/grafana.libsonnet";
local dashboard = grafana.dashboard;
local prometheus = grafana.prometheus;
local row = grafana.row;
local graphPanel = grafana.graphPanel;

local promgrafonnet = import "promgrafonnet/promgrafonnet.libsonnet";
local gauge = promgrafonnet.gauge;

local cpuCoresGraph = graphPanel.new(
        "CPU Cores",
        datasource="prometheus",
        span=9,
        min=0,
    )
    .addTarget(prometheus.target("min(sum(kube_node_status_allocatable_cpu_cores) by (instance))", legendFormat="Allocatable CPU Cores"))
    .addTarget(prometheus.target("max(sum(kube_pod_container_resource_requests_cpu_cores) by (instance))", legendFormat="Requested CPU Cores"));

local cpuCoresGauge = gauge.new(
    "CPU Cores",
    "max(sum(kube_pod_container_resource_requests_cpu_cores) by (instance)) / min(sum(kube_node_status_allocatable_cpu_cores) by (instance)) * 100"
).withLowerBeingBetter();

local cpuCoresRow = row.new()
    .addPanel(cpuCoresGraph)
    .addPanel(cpuCoresGauge);

local memoryGraph = graphPanel.new(
        "Memory",
        datasource="prometheus",
        span=9,
        min=0,
    )
    .addTarget(prometheus.target("min(sum(kube_node_status_allocatable_memory_bytes) by (instance))", legendFormat="Allocatable Memory"))
    .addTarget(prometheus.target("max(sum(kube_pod_container_resource_requests_memory_bytes) by (instance))", legendFormat="Requested Memory"));

local memoryGauge = gauge.new(
    "Memory",
    "max(sum(kube_pod_container_resource_requests_memory_bytes) by (instance)) / min(sum(kube_node_status_allocatable_memory_bytes) by (instance)) * 100"
).withLowerBeingBetter();

local memoryRow = row.new()
    .addPanel(memoryGraph)
    .addPanel(memoryGauge);

dashboard.new("Kubernetes Resource Requests", time_from="now-1h", refresh="10s")
    .addRow(cpuCoresRow)
    .addRow(memoryRow)
