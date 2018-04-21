local grafana = import "grafonnet/grafana.libsonnet";
local dashboard = grafana.dashboard;
local prometheus = grafana.prometheus;
local row = grafana.row;
local graphPanel = grafana.graphPanel;

local promgrafonnet = import "promgrafonnet/promgrafonnet.libsonnet";
local gauge = promgrafonnet.gauge;

local apiservers_up = gauge.new(
    "API Servers UP",
    '(sum(up{job="apiserver"} == 1) / sum(up{job="apiserver"})) * 100'
);

local controller_managers_up = gauge.new(
    "Controller Mangers UP",
    '(sum(up{job="kube-controller-manager"} == 1) / sum(up{job="kube-controller-manager"})) * 100'
);

local schedulers_up = gauge.new(
    "Schedulers UP",
    '(sum(up{job="kube-scheduler"} == 1) / sum(up{job="kube-scheduler"})) * 100'
);

local api_error_rate = gauge.new(
    "API Request Error Rate",
    'max(sum by(instance) (rate(apiserver_request_count{code=~"5.."}[5m])) / sum by(instance) (rate(apiserver_request_count[5m]))) * 100'
);

local firstRow = row.new()
    .addPanel(apiservers_up)
    .addPanel(controller_managers_up)
    .addPanel(schedulers_up)
    .addPanel(api_error_rate);

local api_request_latency = graphPanel.new(
        "API Request Latency",
        datasource="prometheus",
    )
    .addTarget(prometheus.target(
        "sum by(verb) (rate(apiserver_latency_seconds:quantile[5m]) >= 0)",
    ));

local secondRow = row.new()
    .addPanel(api_request_latency);

local api_request_rate = graphPanel.new(
        "API Request Rate",
        datasource="prometheus",
    )
    .addTarget(prometheus.target(
        "sum by(instance) (rate(apiserver_request_count{code!~\"2..\"}[5m]))",
        legendFormat="Error Rate",
    ))
    .addTarget(prometheus.target(
        "sum by(instance) (rate(apiserver_request_count[5m]))",
        legendFormat="Request Rate",
    ));

local thirdRow = row.new()
    .addPanel(api_request_rate);

local e2e_scheduling_latency = graphPanel.new(
        "End to End Scheduling Latency",
        datasource="prometheus",
    )
    .addTarget(prometheus.target(
        "cluster:scheduler_e2e_scheduling_latency_seconds:quantile",
    ));

local fourthRow = row.new()
    .addPanel(e2e_scheduling_latency);

dashboard.new("Kubernetes Control Plane Status", time_from="now-1h", refresh="10s")
    .addRow(firstRow)
    .addRow(secondRow)
    .addRow(thirdRow)
    .addRow(fourthRow)
