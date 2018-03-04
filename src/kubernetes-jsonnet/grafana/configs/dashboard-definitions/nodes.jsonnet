local grafana = import "grafonnet/grafana.libsonnet";
local dashboard = grafana.dashboard;
local row = grafana.row;
local prometheus = grafana.prometheus;
local template = grafana.template;
local graphPanel = grafana.graphPanel;
local promgrafonnet = import "promgrafonnet/promgrafonnet.libsonnet";
local numbersinglestat = promgrafonnet.numbersinglestat;
local gauge = promgrafonnet.gauge;

local idleCPU = graphPanel.new(
        "Idle CPU",
        datasource="prometheus",
        span=6,
        format="percent",
        max=100,
        min=0,
    )
    .addTarget(prometheus.target(
        "100 - (avg by (cpu) (irate(node_cpu{mode=\"idle\", instance=\"$server\"}[5m])) * 100)", legendFormat="{{cpu}}",
        intervalFactor=10,
    ));

local systemLoad = graphPanel.new(
        "System load",
        datasource="prometheus",
        span=6,
        format="percent",
    )
    .addTarget(prometheus.target("node_load1{instance=\"$server\"} * 100", legendFormat="load 1m"))
    .addTarget(prometheus.target("node_load5{instance=\"$server\"} * 100", legendFormat="load 5m"))
    .addTarget(prometheus.target("node_load15{instance=\"$server\"} * 100", legendFormat="load 15m"));

local cpuRow = row.new()
    .addPanel(idleCPU)
    .addPanel(systemLoad);

local memoryGraph = graphPanel.new(
        "Memory Usage",
        datasource="prometheus",
        span=9,
        format="bytes",
    )
    .addTarget(prometheus.target("node_memory_MemTotal{instance=\"$server\"} - node_memory_MemFree{instance=\"$server\"} - node_memory_Buffers{instance=\"$server\"} - node_memory_Cached{instance=\"$server\"}", legendFormat="memory used"))
    .addTarget(prometheus.target("node_memory_Buffers{instance=\"$server\"}", legendFormat="memory buffers"))
    .addTarget(prometheus.target("node_memory_Cached{instance=\"$server\"}", legendFormat="memory cached"))
    .addTarget(prometheus.target("node_memory_MemFree{instance=\"$server\"}", legendFormat="memory free"));

local memoryGauge = gauge.new(
        "Memory Usage",
        "((node_memory_MemTotal{instance=\"$server\"} - node_memory_MemFree{instance=\"$server\"}  - node_memory_Buffers{instance=\"$server\"} - node_memory_Cached{instance=\"$server\"}) / node_memory_MemTotal{instance=\"$server\"}) * 100",
    ).withLowerBeingBetter();

local memoryRow = row.new()
    .addPanel(memoryGraph)
    .addPanel(memoryGauge);

local diskIO = graphPanel.new(
        "Disk I/O",
        datasource="prometheus",
        span=9,
    )
    .addTarget(prometheus.target("sum by (instance) (rate(node_disk_bytes_read{instance=\"$server\"}[2m]))", legendFormat="read"))
    .addTarget(prometheus.target("sum by (instance) (rate(node_disk_bytes_written{instance=\"$server\"}[2m]))", legendFormat="written"))
    .addTarget(prometheus.target("sum by (instance) (rate(node_disk_io_time_ms{instance=\"$server\"}[2m]))", legendFormat="io time")) +
    {
        seriesOverrides: [
            {
              alias: "read",
              yaxis: 1,
            },
            {
              alias: "io time",
              yaxis: 2,
            }
        ],
        yaxes: [
            self.yaxe(format="bytes"),
            self.yaxe(format="ms"),
        ],
    };

local diskSpaceUsage = gauge.new(
        "Disk Space Usage",
        "(sum(node_filesystem_size{device!=\"rootfs\",instance=\"$server\"}) - sum(node_filesystem_free{device!=\"rootfs\",instance=\"$server\"})) / sum(node_filesystem_size{device!=\"rootfs\",instance=\"$server\"}) * 100",
    ).withLowerBeingBetter();

local diskRow = row.new()
    .addPanel(diskIO)
    .addPanel(diskSpaceUsage);

local networkReceived = graphPanel.new(
        "Network Received",
        datasource="prometheus",
        span=6,
        format="bytes",
    )
    .addTarget(prometheus.target("rate(node_network_receive_bytes{instance=\"$server\",device!~\"lo\"}[5m])", legendFormat="{{device}}"));

local networkTransmitted = graphPanel.new(
        "Network Transmitted",
        datasource="prometheus",
        span=6,
        format="bytes",
    )
    .addTarget(prometheus.target("rate(node_network_transmit_bytes{instance=\"$server\",device!~\"lo\"}[5m])", legendFormat="{{device}}"));

local networkRow = row.new()
    .addPanel(networkReceived)
    .addPanel(networkTransmitted);

dashboard.new("Nodes", time_from="now-1h")
    .addTemplate(
        template.new(
            'server',
            'prometheus',
            'label_values(node_boot_time, instance)',
            refresh='time',
        )
    )
    .addRow(cpuRow)
    .addRow(memoryRow)
    .addRow(diskRow)
    .addRow(networkRow)
