local grafana = import "grafonnet/grafana.libsonnet";
local dashboard = grafana.dashboard;
local graphPanel = grafana.graphPanel;
local prometheus = grafana.prometheus;
local promgrafonnet = import "promgrafonnet/promgrafonnet.libsonnet";
local row = grafana.row;
local singlestat = grafana.singlestat;
local template = grafana.template;
local numbersinglestat = promgrafonnet.numbersinglestat;

local memoryRow = row.new()
    .addPanel(
        graphPanel.new(
            "Memory Usage",
            datasource="prometheus",
            min=0,
            format="bytes",
            legend_rightSide=true,
            legend_alignAsTable=true,
            legend_current=true,
            legend_avg=true,
        )
        .addTarget(prometheus.target(
            "sum by(container_name) (container_memory_usage_bytes{namespace=\"$namespace\", pod_name=\"$pod\", container_name=~\"$container\", container_name!=\"POD\"})",
            legendFormat="Current: {{ container_name }}",
        ))
        .addTarget(prometheus.target(
            "sum by(container) (kube_pod_container_resource_requests_memory_bytes{exported_namespace=\"$namespace\", exported_pod=\"$pod\", container=~\"$container\", container!=\"POD\"})",
            legendFormat="Requested: {{ container }}",
        ))
        .addTarget(prometheus.target(
            "sum by(container) (kube_pod_container_resource_limits_memory_bytes{exported_namespace=\"$namespace\", exported_pod=\"$pod\", container=~\"$container\", container!=\"POD\"})",
            legendFormat="Limit: {{ container }}",
        ))
    );

local cpuRow = row.new()
    .addPanel(
        graphPanel.new(
            "CPU Usage",
            datasource="prometheus",
            min=0,
            legend_rightSide=true,
            legend_alignAsTable=true,
            legend_current=true,
            legend_avg=true,
        )
        .addTarget(prometheus.target(
            "sum by (container_name) (rate(container_cpu_usage_seconds_total{image!=\"\",container_name!=\"POD\",pod_name=\"$pod\"}[1m]))",
            legendFormat="{{ container_name }}",
        ))
    );

local networkRow = row.new()
    .addPanel(
        graphPanel.new(
            "Network I/O",
            datasource="prometheus",
            format="bytes",
            min=0,
            legend_rightSide=true,
            legend_alignAsTable=true,
            legend_current=true,
            legend_avg=true,
        )
        .addTarget(prometheus.target(
            "sort_desc(sum by (pod_name) (rate(container_network_receive_bytes_total{pod_name=\"$pod\"}[1m])))",
            legendFormat="{{ pod_name }}",
        ))
    );

dashboard.new("Pods", time_from="now-1h")
    .addTemplate(
        template.new(
            "namespace",
            "prometheus",
            "label_values(kube_pod_info, exported_namespace)",
            label="Namespace",
            refresh="time",
        )
    )
    .addTemplate(
        template.new(
            "pod",
            "prometheus",
            "label_values(kube_pod_info{exported_namespace=~\"$namespace\"}, exported_pod)",
            label="Pod",
            refresh="time",
        )
    )
    .addTemplate(
        template.new(
            "container",
            "prometheus",
            "label_values(kube_pod_container_info{exported_namespace=\"$namespace\", exported_pod=\"$pod\"}, container)",
            label="Container",
            refresh="time",
            includeAll=true,
        )
    )
    .addRow(memoryRow)
    .addRow(cpuRow)
    .addRow(networkRow)
