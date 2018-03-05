local grafana = import "grafonnet/grafana.libsonnet";
local dashboard = grafana.dashboard;
local row = grafana.row;
local prometheus = grafana.prometheus;
local graphPanel = grafana.graphPanel;
local promgrafonnet = import "promgrafonnet/promgrafonnet.libsonnet";
local gauge = promgrafonnet.gauge;

local idleCPU = graphPanel.new(
        "Idle CPU",
        datasource="prometheus",
        span=6,
        format="percent",
        min=0,
    )
    .addTarget(prometheus.target(
        "sum(rate(node_cpu{mode=\"idle\"}[2m])) * 100",
         legendFormat="{{cpu}}",
    ));

local systemLoad = graphPanel.new(
        "System load",
        datasource="prometheus",
        span=6,
        format="percent",
    )
    .addTarget(prometheus.target("sum(node_load1)", legendFormat="load 1m"))
    .addTarget(prometheus.target("sum(node_load5)", legendFormat="load 5m"))
    .addTarget(prometheus.target("sum(node_load15)", legendFormat="load 15m"));

local cpuLoadRow = row.new()
    .addPanel(idleCPU)
    .addPanel(systemLoad);

local memoryGraph = graphPanel.new(
        "Memory Usage",
        datasource="prometheus",
        span=9,
        format="bytes",
    )
    .addTarget(prometheus.target("sum(node_memory_MemTotal) - sum(node_memory_MemFree) - sum(node_memory_Buffers) - sum(node_memory_Cached)", legendFormat="memory used"))
    .addTarget(prometheus.target("sum(node_memory_Buffers)", legendFormat="memory buffers"))
    .addTarget(prometheus.target("sum(node_memory_Cached)", legendFormat="memory cached"))
    .addTarget(prometheus.target("sum(node_memory_MemFree)", legendFormat="memory free"));

local memoryGauge = gauge.new(
        "Memory Usage",
        "((sum(node_memory_MemTotal) - sum(node_memory_MemFree)  - sum(node_memory_Buffers) - sum(node_memory_Cached)) / sum(node_memory_MemTotal)) * 100",
    ).withLowerBeingBetter();

local memoryRow = row.new()
    .addPanel(memoryGraph)
    .addPanel(memoryGauge);

dashboard.new("Kubernetes Capacity Planning", time_from="now-24h")
    .addRow(cpuLoadRow)
    .addRow(memoryRow)

