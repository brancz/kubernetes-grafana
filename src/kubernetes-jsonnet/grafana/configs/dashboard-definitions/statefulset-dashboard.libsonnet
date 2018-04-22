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
        "sum(rate(container_cpu_usage_seconds_total{namespace=\"$statefulset_namespace\",pod_name=~\"$statefulset_name.*\"}[3m]))",
    )
    .withSpanSize(4)
    .withSparkline();

local memoryStat = numbersinglestat.new(
        "Memory",
        "sum(container_memory_usage_bytes{namespace=\"$statefulset_namespace\",pod_name=~\"$statefulset_name.*\"}) / 1024^3",
    )
    .withSpanSize(4)
    .withSparkline();

local networkStat = numbersinglestat.new(
        "Network",
        "sum(rate(container_network_transmit_bytes_total{namespace=\"$statefulset_namespace\",pod_name=~\"$statefulset_name.*\"}[3m])) + sum(rate(container_network_receive_bytes_total{namespace=\"$statefulset_namespace\",pod_name=~\"$statefulset_name.*\"}[3m]))",
    )
    .withSpanSize(4)
    .withSparkline();

local overviewRow = row.new()
    .addPanel(cpuStat)
    .addPanel(memoryStat)
    .addPanel(networkStat);

local desiredReplicasStat = numbersinglestat.new(
        "Desired Replicas",
        "max(kube_statefulset_replicas{namespace=\"$statefulset_namespace\",statefulset=\"$statefulset_name\"}) without (instance, pod)",
    );

local availableReplicasStat = numbersinglestat.new(
        "Replicas of current version",
        "min(kube_statefulset_status_replicas_current{namespace=\"$statefulset_namespace\",statefulset=\"$statefulset_name\"}) without (instance, pod)",
    );

local observedGenerationStat = numbersinglestat.new(
        "Observed Generation",
        "max(kube_statefulset_status_observed_generation{namespace=\"$statefulset_namespace\",statefulset=\"$statefulset_name\"}) without (instance, pod)",
    );

local metadataGenerationStat = numbersinglestat.new(
        "Metadata Generation",
        "max(kube_statefulset_metadata_generation{statefulset=\"$statefulset_name\",namespace=\"$statefulset_namespace\"}) without (instance, pod)",
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
        "max(kube_statefulset_replicas{statefulset=\"$statefulset_name\",namespace=\"$statefulset_namespace\"}) without (instance, pod)",
        legendFormat="replicas specified",
    ))
    .addTarget(prometheus.target(
        "max(kube_statefulset_status_replicas{statefulset=\"$statefulset_name\",namespace=\"$statefulset_namespace\"}) without (instance, pod)",
        legendFormat="replicas created",
    ))
    .addTarget(prometheus.target(
        "min(kube_statefulset_status_replicas_ready{statefulset=\"$statefulset_name\",namespace=\"$statefulset_namespace\"}) without (instance, pod)",
        legendFormat="ready",
    ))
    .addTarget(prometheus.target(
        "min(kube_statefulset_status_replicas_current{statefulset=\"$statefulset_name\",namespace=\"$statefulset_namespace\"}) without (instance, pod)",
        legendFormat="replicas of current version",
    ))
    .addTarget(prometheus.target(
        "min(kube_statefulset_status_replicas_updated{statefulset=\"$statefulset_name\",namespace=\"$statefulset_namespace\"}) without (instance, pod)",
        legendFormat="updated",
    ));

local replicasRow = row.new()
    .addPanel(replicasGraph);

dashboard.new("StatefulSets", time_from="now-1h")
    .addTemplate(
        template.new(
            "statefulset_namespace",
            "prometheus",
            "label_values(kube_statefulset_metadata_generation, namespace)",
            label="Namespace",
            refresh="time",
        )
    )
    .addTemplate(
        template.new(
            "statefulset_name",
            "prometheus",
            "label_values(kube_statefulset_metadata_generation{namespace=\"$statefulset_namespace\"}, statefulset)",
            label="Name",
            refresh="time",
        )
    )
    .addRow(overviewRow)
    .addRow(statsRow)
    .addRow(replicasRow)
