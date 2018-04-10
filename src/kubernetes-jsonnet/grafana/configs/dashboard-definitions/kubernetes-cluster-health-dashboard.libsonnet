local grafana = import "grafonnet/grafana.libsonnet";
local dashboard = grafana.dashboard;
local row = grafana.row;

local promgrafonnet = import "promgrafonnet/promgrafonnet.libsonnet";
local numbersinglestat = promgrafonnet.numbersinglestat;

local control_plane_components_down = numbersinglestat.new(
    "Control Plane Components Down",
    'sum(up{job=~"apiserver|kube-scheduler|kube-controller-manager"} == 0)'
).withTextNullValue("Everything UP and healthy");

local alertsFiring = numbersinglestat.new("Alerts Firing", 'sum(ALERTS{alertstate="firing",alertname!="DeadMansSwitch"})');
local alertsPending = numbersinglestat.new("Alerts Pending", 'sum(ALERTS{alertstate="pending",alertname!="DeadMansSwitch"})');
local crashingPods = numbersinglestat.new("Crashlooping Pods", 'count(increase(kube_pod_container_status_restarts[1h]) > 5)');

local firstRow = row.new()
    .addPanel(control_plane_components_down)
    .addPanel(alertsFiring)
    .addPanel(alertsPending)
    .addPanel(crashingPods);

local nodeNotReady = numbersinglestat.new("Node Not Ready", 'sum(kube_node_status_condition{condition="Ready",status!="true"})');
local nodeDiskPressure = numbersinglestat.new("Node Disk Pressure", 'sum(kube_node_status_condition{condition="DiskPressure",status="true"})');
local nodeMemoryPressure = numbersinglestat.new("Node Memory Pressure", 'sum(kube_node_status_condition{condition="MemoryPressure",status="true"})');
local nodeUnschedulable = numbersinglestat.new("Node Unschedulable", 'sum(kube_node_spec_unschedulable)');

local secondRow = row.new()
    .addPanel(nodeNotReady)
    .addPanel(nodeDiskPressure)
    .addPanel(nodeMemoryPressure)
    .addPanel(nodeUnschedulable);

dashboard.new("Kubernetes Cluster Health", time_from="now-1h", refresh="10s")
    .addRow(firstRow)
    .addRow(secondRow)
