local k = import "ksonnet.beta.3/k.libsonnet";
local deployment = k.apps.v1beta1.deployment;

local deployment = k.apps.v1beta1.deployment;
local container = k.apps.v1beta1.deployment.mixin.spec.template.spec.containersType;
local volume = k.apps.v1beta1.deployment.mixin.spec.template.spec.volumesType;
local containerPort = container.portsType;
local containerVolumeMount = container.volumeMountsType;
local podSelector = deployment.mixin.spec.template.spec.selectorType;

local targetPort = 3000;
local version = "5.0.0";
local podLabels = {"app": "grafana"};

local storageVolumeName = "grafana-storage";
local storageVolume = volume.fromEmptyDir(storageVolumeName);
local storageVolumeMount = containerVolumeMount.new(storageVolumeName, "/data");

local datasourcesVolumeName = "grafana-datasources";
local datasourcesConfigMapName = "grafana-datasources";
local datasourcesVolume = volume.withName(datasourcesVolumeName) + volume.mixin.configMap.withName(datasourcesConfigMapName);
local datasourcesVolumeMount = containerVolumeMount.new(datasourcesVolumeName, "/grafana/conf/provisioning/datasources");

local dashboardsVolumeName = "grafana-dashboards";
local dashboardsConfigMapName = "grafana-dashboards";
local dashboardsVolume = volume.withName(dashboardsVolumeName) + volume.mixin.configMap.withName(dashboardsConfigMapName);
local dashboardsVolumeMount = containerVolumeMount.new(dashboardsVolumeName, "/grafana/conf/provisioning/dashboards");

local dashboardDefinitionsVolumeName = "grafana-dashboard-definitions";
local dashboardDefinitionsConfigMapName = "grafana-dashboard-definitions";
local dashboardDefinitionsVolume = volume.withName(dashboardDefinitionsVolumeName) + volume.mixin.configMap.withName(dashboardDefinitionsConfigMapName);
local dashboardDefinitionsVolumeMount = containerVolumeMount.new(dashboardDefinitionsVolumeName, "/grafana-dashboard-definitions/0");

local c =
  container.new("grafana", "quay.io/coreos/monitoring-grafana:" + version) +
  container.withVolumeMounts([storageVolumeMount, datasourcesVolumeMount, dashboardsVolumeMount, dashboardDefinitionsVolumeMount]) +
  container.withPorts(containerPort.newNamed("http", targetPort)) +
  container.mixin.resources.withRequests({cpu: "100m", memory: "100Mi"}) +
  container.mixin.resources.withLimits({cpu: "200m", memory: "200Mi"});

local d = deployment.new("grafana", 1, c, podLabels) +
  deployment.mixin.spec.selector.withMatchLabels(podLabels) +
  deployment.mixin.metadata.withLabels(podLabels) +
  deployment.mixin.spec.template.spec.withVolumes([storageVolume, datasourcesVolume, dashboardsVolume, dashboardDefinitionsVolume]) +
  deployment.mixin.spec.template.spec.securityContext.withRunAsNonRoot(true) +
  deployment.mixin.spec.template.spec.securityContext.withRunAsUser(65534) +
  deployment.mixin.spec.template.spec.withServiceAccountName("grafana");

d
