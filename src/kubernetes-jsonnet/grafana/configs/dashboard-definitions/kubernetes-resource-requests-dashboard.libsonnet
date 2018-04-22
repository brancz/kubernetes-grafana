local grafana = import "grafonnet/grafana.libsonnet";
local dashboard = grafana.dashboard;
local prometheus = grafana.prometheus;
local row = grafana.row;
local graphPanel = grafana.graphPanel;

local promgrafonnet = import "promgrafonnet/promgrafonnet.libsonnet";
local gauge = promgrafonnet.gauge;

local cpuCoresGraph = graphPanel.new(
        "CPU Cores"
        datasource="prometheus",
        span=9,
        min=0,
    )
    .addTarget("min(sum(kube_node_status_allocatable_cpu_cores) by (instance))", legendFormat="Allocatable CPU Cores")
    .addTarget("max(sum(kube_pod_container_resource_requests_cpu_cores) by (instance))", legendFormat="Requested CPU Cores");

local cpuCoresGauge = gauge.new(
    "CPU Cores",
    "max(sum(kube_pod_container_resource_requests_cpu_cores) by (instance)) / min(sum(kube_node_status_allocatable_cpu_cores) by (instance)) * 100"
).withLowerBeingBetter();

local cpuCoresRow = row.new()
    .addPanel(cpuCoresGraph)
    .addPanel(cpuCoresGauge);

local cpuCoresGraph = graphPanel.new(
        "CPU Cores"
        datasource="prometheus",
        span=9,
        min=0,
    )
    .addTarget("min(sum(kube_node_status_allocatable_cpu_cores) by (instance))", legendFormat="Allocatable CPU Cores")
    .addTarget("max(sum(kube_pod_container_resource_requests_cpu_cores) by (instance))", legendFormat="Requested CPU Cores");

local cpuCoresGauge = gauge.new(
    "CPU Cores",
    "max(sum(kube_pod_container_resource_requests_cpu_cores) by (instance)) / min(sum(kube_node_status_allocatable_cpu_cores) by (instance)) * 100"
).withLowerBeingBetter();

local cpuCoresRow = row.new()
    .addPanel(cpuCoresGraph)
    .addPanel(cpuCoresGauge);

dashboard.new("Kubernetes Control Plane Status", time_from="now-1h", refresh="10s")
    .addRow(firstRow)
    .addRow(secondRow)
    .addRow(thirdRow)
    .addRow(fourthRow)
