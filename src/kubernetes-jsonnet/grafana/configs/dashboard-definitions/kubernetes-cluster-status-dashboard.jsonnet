local grafana = import "grafonnet/grafana.libsonnet";
local dashboard = grafana.dashboard;
local row = grafana.row;

local promgrafonnet = import "promgrafonnet/promgrafonnet.libsonnet";
local numbersinglestat = promgrafonnet.numbersinglestat;
local gauge = promgrafonnet.gauge;

local controlPlaneUp = numbersinglestat.new("Control Plane UP", 'sum(up{job=~"apiserver|kube-scheduler|kube-controller-manager"} == 0)').withSpanSize(6);
local alertsFiring   = numbersinglestat.new("Alerts Firing",    'sum(ALERTS{alertstate="firing",alertname!="DeadMansSwitch"})').withSpanSize(6);

local clusterHealthRow = row.new()
    .addPanel(controlPlaneUp)
    .addPanel(alertsFiring);

local apiserversUp         = gauge.new("API Servers UP",         '(sum(up{job="apiserver"} == 1) / count(up{job="apiserver"})) * 100');
local controllerManagersUp = gauge.new("Controller Managers UP", '(sum(up{job="kube-controller-manager"} == 1) / count(up{job="kube-controller-manager"})) * 100');
local schedulersUp         = gauge.new("Schedulers Up",          '(sum(up{job="kube-scheduler"} == 1) / count(up{job="kube-scheduler"})) * 100');

local crashingControlPlanePods  = numbersinglestat.new("Crashlooping Control Plane Pods", 'count(increase(kube_pod_container_status_restarts{namespace=~"kube-system|tectonic-system"}[1h]) > 5)');

local controlPlaneStatusRow = row.new()
    .addPanel(apiserversUp)
    .addPanel(controllerManagersUp)
    .addPanel(schedulersUp)
    .addPanel(crashingControlPlanePods);

local cpuUtilization        = gauge.new("CPU Utilization",        'sum(100 - (avg by (instance) (rate(node_cpu{job="node-exporter",mode="idle"}[5m])) * 100)) / count(node_cpu{job="node-exporter",mode="idle"})').withLowerBeingBetter();
local memoryUtilization     = gauge.new("Memory Utilization",     '((sum(node_memory_MemTotal) - sum(node_memory_MemFree) - sum(node_memory_Buffers) - sum(node_memory_Cached)) / sum(node_memory_MemTotal)) * 100').withLowerBeingBetter();
local filesystemUtilization = gauge.new("Filesystem Utilization", '(sum(node_filesystem_size{device!="rootfs"}) - sum(node_filesystem_free{device!="rootfs"})) / sum(node_filesystem_size{device!="rootfs"})').withLowerBeingBetter();
local podUtilization        = gauge.new("Pod Utilization",        '100 - (sum(kube_node_status_capacity_pods) - sum(kube_pod_info)) / sum(kube_node_status_capacity_pods) * 100').withLowerBeingBetter();

local capacityPlanningRow = row.new()
    .addPanel(cpuUtilization)
    .addPanel(memoryUtilization)
    .addPanel(filesystemUtilization)
    .addPanel(podUtilization);

dashboard.new("Kubernetes Cluster Status", time_from="now-1h", refresh="10s")
    .addRow(clusterHealthRow)
    .addRow(controlPlaneStatusRow)
    .addRow(capacityPlanningRow)
