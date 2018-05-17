local k = import 'ksonnet/ksonnet.beta.3/k.libsonnet';

{
  _config+:: {
    namespace: 'default',

    versions+:: {
      grafana: '5.1.0',
    },

    imageRepos+:: {
      grafana: 'grafana/grafana',
    },

    grafana+:: {
      dashboards: {},
      datasources: [{
        name: 'prometheus',
        type: 'prometheus',
        access: 'proxy',
        org_id: 1,
        url: 'http://prometheus-k8s.monitoring.svc:9090',
        version: 1,
        etitable: false,
      }],
      config: null,
    },
  },
  grafanaDashboards: {},
  grafana+: {
    [if $._config.grafana.config != null then 'config']:
      local configMap = k.core.v1.configMap;
      configMap.new('grafana-config', { 'grafana.ini': std.manifestIni($._config.grafana.config) }) +
      configMap.mixin.metadata.withNamespace($._config.namespace),
    dashboardDefinitions:
      local configMap = k.core.v1.configMap;
      configMap.new('grafana-dashboard-definitions', { [name]: std.manifestJsonEx($._config.grafana.dashboards[name], '    ') for name in std.objectFields($._config.grafana.dashboards) }) +
      configMap.mixin.metadata.withNamespace($._config.namespace),
    dashboardSources:
      local configMap = k.core.v1.configMap;
      local dashboardSources = import 'configs/dashboard-sources/dashboards.libsonnet';

      configMap.new('grafana-dashboards', { 'dashboards.yaml': std.manifestJsonEx(dashboardSources, '    ') }) +
      configMap.mixin.metadata.withNamespace($._config.namespace),
    dashboardDatasources:
      local configMap = k.core.v1.configMap;
      configMap.new('grafana-datasources', { 'prometheus.yaml': std.manifestJsonEx({ datasources: $._config.grafana.datasources }, '    ') }) +
      configMap.mixin.metadata.withNamespace($._config.namespace),
    service:
      local service = k.core.v1.service;
      local servicePort = k.core.v1.service.mixin.spec.portsType;

      local grafanaServiceNodePort = servicePort.newNamed('http', 3000, 'http');

      service.new('grafana', $.grafana.deployment.spec.selector.matchLabels, grafanaServiceNodePort) +
      service.mixin.metadata.withNamespace($._config.namespace),
    serviceAccount:
      local serviceAccount = k.core.v1.serviceAccount;
      serviceAccount.new('grafana') +
      serviceAccount.mixin.metadata.withNamespace($._config.namespace),
    deployment:
      local deployment = k.apps.v1beta2.deployment;
      local container = k.apps.v1beta2.deployment.mixin.spec.template.spec.containersType;
      local volume = k.apps.v1beta2.deployment.mixin.spec.template.spec.volumesType;
      local containerPort = container.portsType;
      local containerVolumeMount = container.volumeMountsType;
      local podSelector = deployment.mixin.spec.template.spec.selectorType;

      local targetPort = 3000;
      local podLabels = { app: 'grafana' };

      local configVolumeName = 'grafana-config';
      local configConfigMapName = 'grafana-config';
      local configVolume = volume.withName(configVolumeName) + volume.mixin.configMap.withName(configConfigMapName);
      local configVolumeMount = containerVolumeMount.new(configVolumeName, '/etc/grafana');

      local storageVolumeName = 'grafana-storage';
      local storageVolume = volume.fromEmptyDir(storageVolumeName);
      local storageVolumeMount = containerVolumeMount.new(storageVolumeName, '/var/lib/grafana');

      local datasourcesVolumeName = 'grafana-datasources';
      local datasourcesConfigMapName = 'grafana-datasources';
      local datasourcesVolume = volume.withName(datasourcesVolumeName) + volume.mixin.configMap.withName(datasourcesConfigMapName);
      local datasourcesVolumeMount = containerVolumeMount.new(datasourcesVolumeName, '/etc/grafana/provisioning/datasources');

      local dashboardsVolumeName = 'grafana-dashboards';
      local dashboardsConfigMapName = 'grafana-dashboards';
      local dashboardsVolume = volume.withName(dashboardsVolumeName) + volume.mixin.configMap.withName(dashboardsConfigMapName);
      local dashboardsVolumeMount = containerVolumeMount.new(dashboardsVolumeName, '/etc/grafana/provisioning/dashboards');

      local dashboardDefinitionsVolumeName = 'grafana-dashboard-definitions';
      local dashboardDefinitionsConfigMapName = 'grafana-dashboard-definitions';
      local dashboardDefinitionsVolume = volume.withName(dashboardDefinitionsVolumeName) + volume.mixin.configMap.withName(dashboardDefinitionsConfigMapName);
      local dashboardDefinitionsVolumeMount = containerVolumeMount.new(dashboardDefinitionsVolumeName, '/grafana-dashboard-definitions/0');

      local volumeMounts = [
        storageVolumeMount,
        datasourcesVolumeMount,
        dashboardsVolumeMount,
        dashboardDefinitionsVolumeMount,
      ] + if $._config.grafana.config != null then [configVolumeMount] else [];

      local volumes = [
        storageVolume,
        datasourcesVolume,
        dashboardsVolume,
        dashboardDefinitionsVolume,
      ] + if $._config.grafana.config != null then [configVolume] else [];

      local c =
        container.new('grafana', $._config.imageRepos.grafana + ':' + $._config.versions.grafana) +
        container.withVolumeMounts(volumeMounts) +
        container.withPorts(containerPort.newNamed('http', targetPort)) +
        container.mixin.resources.withRequests({ cpu: '100m', memory: '100Mi' }) +
        container.mixin.resources.withLimits({ cpu: '200m', memory: '200Mi' });

      deployment.new('grafana', 1, c, podLabels) +
      deployment.mixin.metadata.withNamespace($._config.namespace) +
      deployment.mixin.metadata.withLabels(podLabels) +
      deployment.mixin.spec.selector.withMatchLabels(podLabels) +
      deployment.mixin.spec.template.spec.withVolumes(volumes) +
      deployment.mixin.spec.template.spec.securityContext.withRunAsNonRoot(true) +
      deployment.mixin.spec.template.spec.securityContext.withRunAsUser(65534) +
      deployment.mixin.spec.template.spec.withServiceAccountName('grafana'),
  },
}
