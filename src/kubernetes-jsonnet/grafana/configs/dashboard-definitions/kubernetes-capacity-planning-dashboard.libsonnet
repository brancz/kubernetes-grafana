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
        "System Load",
        datasource="prometheus",
        span=6,
        format="percent",
        min=0,
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
        min=0,
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

local diskGraph = graphPanel.new(
        "Disk I/O",
        datasource="prometheus",
        span=9,
        format="bytes",
        min=0,
    )
    .addTarget(prometheus.target("sum(rate(node_disk_bytes_read[5m]))", legendFormat="read"))
    .addTarget(prometheus.target("sum(rate(node_disk_bytes_written[5m]))", legendFormat="written"))
    .addTarget(prometheus.target("sum(rate(node_disk_io_time_ms[5m]))", legendFormat="io time"));

local diskGauge = gauge.new(
        "Disk Space Usage",
        "(sum(node_filesystem_size{device!=\"rootfs\"}) - sum(node_filesystem_free{device!=\"rootfs\"})) / sum(node_filesystem_size{device!=\"rootfs\"}) * 100"
    ).withLowerBeingBetter();

local diskRow = row.new()
    .addPanel(diskGraph)
    .addPanel(diskGauge);

local networkReceivedGraph = graphPanel.new(
        "Network Received",
        datasource="prometheus",
        span=6,
        format="bytes",
        min=0,
    )
    .addTarget(prometheus.target("sum(rate(node_network_receive_bytes{device!~\"lo\"}[5m]))"));

local networkTransmittedGraph = graphPanel.new(
        "Network Transmitted",
        datasource="prometheus",
        span=6,
        format="bytes",
        min=0,
    )
    .addTarget(prometheus.target("sum(rate(node_network_transmit_bytes{device!~\"lo\"}[5m]))"));

local networkRow = row.new()
    .addPanel(networkReceivedGraph)
    .addPanel(networkTransmittedGraph);

local podUtilizationGraph = graphPanel.new(
        "Cluster Pod Utilization",
        datasource="prometheus",
        span=9,
        min=0,
    )
    .addTarget(prometheus.target("sum(kube_pod_info)", legendFormat="Current Number of Pods"))
    .addTarget(prometheus.target("sum(kube_node_status_capacity_pods)", legendFormat="Maximum Capacity of Pods"));

local podUtilizationGauge = gauge.new(
        "Pod Utilization",
        "100 - (sum(kube_node_status_capacity_pods) - sum(kube_pod_info)) / sum(kube_node_status_capacity_pods) * 100"
    ).withLowerBeingBetter();

local utilizationRow = row.new()
    .addPanel(podUtilizationGraph)
    .addPanel(podUtilizationGauge);

dashboard.new("Kubernetes Capacity Planning", time_from="now-24h")
    .addRow(cpuLoadRow)
    .addRow(memoryRow)
    .addRow(diskRow)
    .addRow(networkRow)
    .addRow(utilizationRow)
