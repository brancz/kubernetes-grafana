local k = import "ksonnet/ksonnet.beta.3/k.libsonnet";

{
    _config+:: {
        namespace: "default",

        versions+:: {
            grafana: "5.0.3",
        },

        imageRepos+:: {
            grafana: "quay.io/coreos/monitoring-grafana",
        },

        grafana+:: {
            dashboards: {},
        },
    },
    grafanaDashboards: {},
    grafana+: {
        dashboardDefinitions:
            local configMap = k.core.v1.configMap;
            configMap.new("grafana-dashboard-definitions", {[name]: std.manifestJsonEx($._config.grafana.dashboards[name], "    ") for name in std.objectFields($._config.grafana.dashboards)}) +
              configMap.mixin.metadata.withNamespace($._config.namespace),
        dashboardSources:
            local configMap = k.core.v1.configMap;
            local dashboardSources = import "configs/dashboard-sources/dashboards.libsonnet";

            configMap.new("grafana-dashboards", {"dashboards.yaml": std.manifestJsonEx(dashboardSources, "    ")}) +
              configMap.mixin.metadata.withNamespace($._config.namespace),
        dashboardDatasources:
            local prometheusDatasource = import "configs/datasources/prometheus.libsonnet";
            local configMap = k.core.v1.configMap;
            configMap.new("grafana-datasources", {"prometheus.yaml": std.manifestJsonEx(prometheusDatasource, "    ")}) +
              configMap.mixin.metadata.withNamespace($._config.namespace),
        service:
            local service = k.core.v1.service;
            local servicePort = k.core.v1.service.mixin.spec.portsType;

            local grafanaServiceNodePort = servicePort.newNamed("http", 3000, "http");

            service.new("grafana", $.grafana.deployment.spec.selector.matchLabels, grafanaServiceNodePort) +
              service.mixin.metadata.withNamespace($._config.namespace),
        serviceAccount:
            local serviceAccount = k.core.v1.serviceAccount;
            serviceAccount.new("grafana") +
              serviceAccount.mixin.metadata.withNamespace($._config.namespace),
        deployment:
            local deployment = k.apps.v1beta2.deployment;
            local container = k.apps.v1beta2.deployment.mixin.spec.template.spec.containersType;
            local volume = k.apps.v1beta2.deployment.mixin.spec.template.spec.volumesType;
            local containerPort = container.portsType;
            local containerVolumeMount = container.volumeMountsType;
            local podSelector = deployment.mixin.spec.template.spec.selectorType;

            local targetPort = 3000;
            local podLabels = { app: "grafana" };

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
              container.new("grafana", $._config.imageRepos.grafana + ":" + $._config.versions.grafana) +
              container.withVolumeMounts([storageVolumeMount, datasourcesVolumeMount, dashboardsVolumeMount, dashboardDefinitionsVolumeMount]) +
              container.withPorts(containerPort.newNamed("http", targetPort)) +
              container.mixin.resources.withRequests({ cpu: "100m", memory: "100Mi" }) +
              container.mixin.resources.withLimits({ cpu: "200m", memory: "200Mi" });

            deployment.new("grafana", 1, c, podLabels) +
              deployment.mixin.metadata.withNamespace($._config.namespace) +
              deployment.mixin.metadata.withLabels(podLabels) +
              deployment.mixin.spec.selector.withMatchLabels(podLabels) +
              deployment.mixin.spec.template.spec.withVolumes([storageVolume, datasourcesVolume, dashboardsVolume, dashboardDefinitionsVolume]) +
              deployment.mixin.spec.template.spec.securityContext.withRunAsNonRoot(true) +
              deployment.mixin.spec.template.spec.securityContext.withRunAsUser(65534) +
              deployment.mixin.spec.template.spec.withServiceAccountName("grafana"),
    }
}
