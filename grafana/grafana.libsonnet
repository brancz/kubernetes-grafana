local k = import 'ksonnet/ksonnet.beta.3/k.libsonnet';
local configMapList = k.core.v1.configMapList;

{
  _config+:: {
    namespace: 'default',

    versions+:: {
      grafana: '6.0.1',
    },

    imageRepos+:: {
      grafana: 'grafana/grafana',
    },

    grafana+:: {
      name: 'grafana',
      dashboards: {},
      datasources: [{
        name: 'prometheus',
        type: 'prometheus',
        access: 'proxy',
        orgId: 1,
        url: 'http://prometheus-k8s.' + $._config.namespace + '.svc:9090',
        version: 1,
        editable: false,
      }],
      config: {},
      ldap: null,
      plugins: [],
      container: {
        requests: { cpu: '100m', memory: '100Mi' },
        limits: { cpu: '200m', memory: '200Mi' },
      },
    },
  },
  grafanaDashboards:: {},
  grafana+: {
    [if std.length($._config.grafana.config) > 0 then 'config']:
      local secret = k.core.v1.secret;
      local grafanaConfig = { 'grafana.ini': std.base64(std.manifestIni($._config.grafana.config)) } +
                            if $._config.grafana.ldap != null then { 'ldap.toml': std.base64($._config.grafana.ldap) } else {};
      secret.new($._config.grafana.name + '-config', grafanaConfig) +
      secret.mixin.metadata.withNamespace($._config.namespace),
    dashboardDefinitions:
      local configMap = k.core.v1.configMap;
      configMapList.new(
        [
          local dashboardName = $._config.grafana.name + '-dashboard-' + std.strReplace(name, '.json', '');
          configMap.new(dashboardName, { [name]: std.manifestJsonEx($._config.grafana.dashboards[name], '    ') }) +
          configMap.mixin.metadata.withNamespace($._config.namespace)
          for name in std.objectFields($._config.grafana.dashboards)
        ]
      ),
    dashboardSources:
      local configMap = k.core.v1.configMap;
      local dashboardSources = import 'configs/dashboard-sources/dashboards.libsonnet';

      configMap.new($._config.grafana.name + '-dashboards', { 'dashboards.yaml': std.manifestJsonEx(dashboardSources, '    ') }) +
      configMap.mixin.metadata.withNamespace($._config.namespace),
    dashboardDatasources:
      local secret = k.core.v1.secret;
      secret.new($._config.grafana.name + '-datasources', { 'datasources.yaml': std.base64(std.manifestJsonEx({
        apiVersion: 1,
        datasources: $._config.grafana.datasources,
      }, '    ')) }) +
      secret.mixin.metadata.withNamespace($._config.namespace),
    service:
      local service = k.core.v1.service;
      local servicePort = k.core.v1.service.mixin.spec.portsType;

      local grafanaServiceNodePort = servicePort.newNamed('http', 3000, 'http');

      service.new($._config.grafana.name, $.grafana.deployment.spec.selector.matchLabels, grafanaServiceNodePort) +
      service.mixin.metadata.withLabels({ app: 'grafana' }) +
      service.mixin.metadata.withNamespace($._config.namespace),
    serviceAccount:
      local serviceAccount = k.core.v1.serviceAccount;
      serviceAccount.new($._config.grafana.name) +
      serviceAccount.mixin.metadata.withNamespace($._config.namespace),
    deployment:
      local deployment = k.apps.v1beta2.deployment;
      local container = k.apps.v1beta2.deployment.mixin.spec.template.spec.containersType;
      local volume = k.apps.v1beta2.deployment.mixin.spec.template.spec.volumesType;
      local containerPort = container.portsType;
      local containerVolumeMount = container.volumeMountsType;
      local podSelector = deployment.mixin.spec.template.spec.selectorType;
      local env = container.envType;

      local targetPort = 3000;
      local portName = 'http';
      local podLabels = { app: 'grafana' };

      local configVolumeName = 'grafana-config';
      local configVolume = volume.withName(configVolumeName) + volume.mixin.secret.withSecretName(self.config.metadata.name);
      local configVolumeMount = containerVolumeMount.new(configVolumeName, '/etc/grafana');

      local storageVolumeName = 'grafana-storage';
      local storageVolume = volume.fromEmptyDir(storageVolumeName);
      local storageVolumeMount = containerVolumeMount.new(storageVolumeName, '/var/lib/grafana');

      local datasourcesVolumeName = 'grafana-datasources';
      local datasourcesVolume = volume.withName(datasourcesVolumeName) + volume.mixin.secret.withSecretName(self.dashboardDatasources.metadata.name);
      local datasourcesVolumeMount = containerVolumeMount.new(datasourcesVolumeName, '/etc/grafana/provisioning/datasources');

      local dashboardsVolumeName = 'grafana-dashboards';
      local dashboardsVolume = volume.withName(dashboardsVolumeName) + volume.mixin.configMap.withName(self.dashboardSources.metadata.name);
      local dashboardsVolumeMount = containerVolumeMount.new(dashboardsVolumeName, '/etc/grafana/provisioning/dashboards');

      local volumeMounts =
        [
          storageVolumeMount,
          datasourcesVolumeMount,
        ] +
        (if std.length(self.dashboardDefinitions.items) > 0 then [dashboardsVolumeMount] else []) +
        [
          local dashboardName = cfgMap.metadata.name;
          containerVolumeMount.new(dashboardName, '/grafana-dashboard-definitions/0/' + dashboardName)
          for cfgMap in self.dashboardDefinitions.items
        ] +
        if std.length($._config.grafana.config) > 0 then [configVolumeMount] else [];

      local volumes =
        [
          storageVolume,
          datasourcesVolume,
        ] +
        (if std.length(self.dashboardDefinitions.items) > 0 then [dashboardsVolume] else []) +
        [
          local dashboardName = cfgMap.metadata.name;
          volume.withName(dashboardName) +
          volume.mixin.configMap.withName(dashboardName)
          for cfgMap in self.dashboardDefinitions.items
        ] +
        if std.length($._config.grafana.config) > 0 then [configVolume] else [];

      local c =
        container.new('grafana', $._config.imageRepos.grafana + ':' + $._config.versions.grafana) +
        (if std.length($._config.grafana.plugins) == 0 then {} else container.withEnv([env.new('GF_INSTALL_PLUGINS', std.join(',', $._config.grafana.plugins))])) +
        container.withVolumeMounts(volumeMounts) +
        container.withPorts(containerPort.newNamed(portName, targetPort)) +
        container.mixin.readinessProbe.httpGet.withPath('/api/health') +
        container.mixin.readinessProbe.httpGet.withPort(portName) +
        container.mixin.resources.withRequests($._config.grafana.container.requests) +
        container.mixin.resources.withLimits($._config.grafana.container.limits);

      deployment.new($._config.grafana.name, 1, c, podLabels) +
      deployment.mixin.metadata.withNamespace($._config.namespace) +
      deployment.mixin.metadata.withLabels(podLabels) +
      deployment.mixin.spec.selector.withMatchLabels(podLabels) +
      deployment.mixin.spec.template.spec.withNodeSelector({ 'beta.kubernetes.io/os': 'linux' }) +
      deployment.mixin.spec.template.spec.withVolumes(volumes) +
      deployment.mixin.spec.template.spec.securityContext.withRunAsNonRoot(true) +
      deployment.mixin.spec.template.spec.securityContext.withRunAsUser(65534) +
      deployment.mixin.spec.template.spec.withServiceAccountName(self.serviceAccount.metadata.name),
  },
}
