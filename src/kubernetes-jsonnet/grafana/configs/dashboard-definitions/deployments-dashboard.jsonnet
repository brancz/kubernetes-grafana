local grafana = import "grafonnet/grafana.libsonnet";
local dashboard = grafana.dashboard;
local graphPanel = grafana.graphPanel;
local prometheus = grafana.prometheus;
local promgrafonnet = import "promgrafonnet/promgrafonnet.libsonnet";
local row = grafana.row;
local singlestat = grafana.singlestat;
local template = grafana.template;
local numbersinglestat = promgrafonnet.numbersinglestat;

local cpuStat = numbersinglestat.new(
        "CPU",
        "sum(rate(container_cpu_usage_seconds_total{namespace=\"$deployment_namespace\",pod_name=~\"$deployment_name.*\"}[3m]))",
    )
    .withSpanSize(4)
    .withSparkline();

local memoryStat = numbersinglestat.new(
        "Memory",
        "sum(container_memory_usage_bytes{namespace=\"$deployment_namespace\",pod_name=~\"$deployment_name.*\"}) / 1024^3",
    )
    .withSpanSize(4)
    .withSparkline();

local networkStat = numbersinglestat.new(
        "Network",
        "sum(rate(container_network_transmit_bytes_total{namespace=\"$deployment_namespace\",pod_name=~\"$deployment_name.*\"}[3m])) + sum(rate(container_network_receive_bytes_total{namespace=\"$deployment_namespace\",pod_name=~\"$deployment_name.*\"}[3m]))",
    )
    .withSpanSize(4)
    .withSparkline();

local overviewRow = row.new()
    .addPanel(cpuStat)
    .addPanel(memoryStat)
    .addPanel(networkStat);

local desiredReplicasStat = numbersinglestat.new(
        "Desired Replicas",
        "max(kube_deployment_spec_replicas{exported_namespace=\"$deployment_namespace\",deployment=\"$deployment_name\"}) without (instance, pod)",
    );

local availableReplicasStat = numbersinglestat.new(
        "Available Replicas",
        "min(kube_deployment_status_replicas_available{exported_namespace=\"$deployment_namespace\",deployment=\"$deployment_name\"}) without (instance, pod)",
    );

local observedGenerationStat = numbersinglestat.new(
        "Observed Generation",
        "max(kube_deployment_status_observed_generation{exported_namespace=\"$deployment_namespace\",deployment=\"$deployment_name\"}) without (instance, pod)",
    );

local metadataGenerationStat = numbersinglestat.new(
        "Metadata Generation",
        "max(kube_deployment_metadata_generation{deployment=\"$deployment_name\",exported_namespace=\"$deployment_namespace\"}) without (instance, pod)",
    );

local statsRow = row.new(height="100px")
    .addPanel(desiredReplicasStat)
    .addPanel(availableReplicasStat)
    .addPanel(observedGenerationStat)
    .addPanel(metadataGenerationStat);

local replicasGraph = graphPanel.new(
        "Replicas",
        datasource="prometheus",
    )
    .addTarget(prometheus.target(
        "max(kube_deployment_status_replicas{deployment=\"$deployment_name\",exported_namespace=\"$deployment_namespace\"}) without (instance, pod)",
        legendFormat="current replicas",
    ))
    .addTarget(prometheus.target(
        "min(kube_deployment_status_replicas_available{deployment=\"$deployment_name\",exported_namespace=\"$deployment_namespace\"}) without (instance, pod)",
        legendFormat="available",
    ))
    .addTarget(prometheus.target(
        "max(kube_deployment_status_replicas_unavailable{deployment=\"$deployment_name\",exported_namespace=\"$deployment_namespace\"}) without (instance, pod)",
        legendFormat="unavailable",
    ))
    .addTarget(prometheus.target(
        "min(kube_deployment_status_replicas_updated{deployment=\"$deployment_name\",exported_namespace=\"$deployment_namespace\"}) without (instance, pod)",
        legendFormat="updated",
    ))
    .addTarget(prometheus.target(
        "max(kube_deployment_spec_replicas{deployment=\"$deployment_name\",exported_namespace=\"$deployment_namespace\"}) without (instance, pod)",
        legendFormat="desired",
    ));

local replicasRow = row.new()
    .addPanel(replicasGraph);

dashboard.new("Deployments", time_from="now-1h")
    .addTemplate(
        template.new(
            "deployment_namespace",
            "prometheus",
            "label_values(kube_deployment_metadata_generation, exported_namespace)",
            label="Namespace",
            refresh="time",
        )
    )
    .addTemplate(
        template.new(
            "deployment_name",
            "prometheus",
            "label_values(kube_deployment_metadata_generation{exported_namespace=\"$deployment_namespace\"}, deployment)",
            label="Name",
            refresh="time",
        )
    )
    .addRow(overviewRow)
    .addRow(statsRow)
    .addRow(replicasRow)

