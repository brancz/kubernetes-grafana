local k = import 'ksonnet/ksonnet.beta.4/k.libsonnet';

{
  _config+:: {
    namespace: 'default',

    versions+:: {
      grafana: '6.6.0',
      grafanaImageRenderer: '1.0.9',
    },

    imageRepos+:: {
      grafana: 'grafana/grafana',
      grafanaImageRenderer: 'grafana/grafana-image-renderer',
    },

    prometheus+:: {
      name: 'k8s',
      serviceName: 'prometheus-' + $._config.prometheus.name,
    },

    grafana+:: {
      dashboards: {},
      rawDashboards: {},
      datasources: [{
        name: 'prometheus',
        type: 'prometheus',
        access: 'proxy',
        orgId: 1,
        url: 'http://' + $._config.prometheus.serviceName + '.' + $._config.namespace + '.svc:9090',
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
      imageRendererContainer: {
        requests: { cpu: '100m', memory: '100Mi' },
        limits: { cpu: '200m', memory: '200Mi' },
      },
    },
  },
  grafanaDashboards: {},
  grafana+: {
    [if std.length($._config.grafana.config) > 0 then 'config']:
      local secret = k.core.v1.secret;
      local grafanaConfig = { 'grafana.ini': std.base64(std.encodeUTF8(std.manifestIni($._config.grafana.config))) } +
                            if $._config.grafana.ldap != null then { 'ldap.toml': std.base64(std.encodeUTF8($._config.grafana.ldap)) } else {};
      secret.new('grafana-config', grafanaConfig) +
      secret.mixin.metadata.withNamespace($._config.namespace),
    dashboardDefinitions:
      local configMap = k.core.v1.configMap;
      [
        local dashboardName = 'grafana-dashboard-' + std.strReplace(name, '.json', '');
        configMap.new(dashboardName, { [name]: std.manifestJsonEx($._config.grafana.dashboards[name], '    ') }) +
        configMap.mixin.metadata.withNamespace($._config.namespace)

        for name in std.objectFields($._config.grafana.dashboards)
      ] + if std.length($._config.grafana.rawDashboards) > 0 then
        [
          local dashboardName = 'grafana-dashboard-' + std.strReplace(name, '.json', '');
          configMap.new(dashboardName, { [name]: $._config.grafana.rawDashboards[name] }) +
          configMap.mixin.metadata.withNamespace($._config.namespace)

          for name in std.objectFields($._config.grafana.rawDashboards)
        ] else [],
    dashboardSources:
      local configMap = k.core.v1.configMap;
      local dashboardSources = import 'configs/dashboard-sources/dashboards.libsonnet';

      configMap.new('grafana-dashboards', { 'dashboards.yaml': std.manifestJsonEx(dashboardSources, '    ') }) +
      configMap.mixin.metadata.withNamespace($._config.namespace),
    dashboardDatasources:
      local secret = k.core.v1.secret;
      secret.new('grafana-datasources', { 'datasources.yaml': std.base64(std.encodeUTF8(std.manifestJsonEx({
        apiVersion: 1,
        datasources: $._config.grafana.datasources,
      }, '    '))) }) +
      secret.mixin.metadata.withNamespace($._config.namespace),
    service:
      local service = k.core.v1.service;
      local servicePort = k.core.v1.service.mixin.spec.portsType;

      local grafanaServiceNodePort = servicePort.newNamed('http', 3000, 'http');

      service.new('grafana', $.grafana.deployment.spec.selector.matchLabels, grafanaServiceNodePort) +
      service.mixin.metadata.withLabels({ app: 'grafana' }) +
      service.mixin.metadata.withNamespace($._config.namespace),
    serviceAccount:
      local serviceAccount = k.core.v1.serviceAccount;
      serviceAccount.new('grafana') +
      serviceAccount.mixin.metadata.withNamespace($._config.namespace),
    deployment:
      local deployment = k.apps.v1.deployment;
      local container = k.apps.v1.deployment.mixin.spec.template.spec.containersType;
      local volume = k.apps.v1.deployment.mixin.spec.template.spec.volumesType;
      local containerPort = container.portsType;
      local containerVolumeMount = container.volumeMountsType;
      local podSelector = deployment.mixin.spec.template.spec.selectorType;
      local env = container.envType;

      local targetPort = 3000;
      local imageRendererPort = 8081;
      local portName = 'http';
      local podLabels = { app: 'grafana' };

      local configVolumeName = 'grafana-config';
      local configSecretName = 'grafana-config';
      local configVolume = volume.withName(configVolumeName) + volume.mixin.secret.withSecretName(configSecretName);
      local configVolumeMount = containerVolumeMount.new(configVolumeName, '/etc/grafana');

      local storageVolumeName = 'grafana-storage';
      local storageVolume = volume.fromEmptyDir(storageVolumeName);
      local storageVolumeMount = containerVolumeMount.new(storageVolumeName, '/var/lib/grafana');

      local datasourcesVolumeName = 'grafana-datasources';
      local datasourcesSecretName = 'grafana-datasources';
      local datasourcesVolume = volume.withName(datasourcesVolumeName) + volume.mixin.secret.withSecretName(datasourcesSecretName);
      local datasourcesVolumeMount = containerVolumeMount.new(datasourcesVolumeName, '/etc/grafana/provisioning/datasources');

      local dashboardsVolumeName = 'grafana-dashboards';
      local dashboardsConfigMapName = 'grafana-dashboards';
      local dashboardsVolume = volume.withName(dashboardsVolumeName) + volume.mixin.configMap.withName(dashboardsConfigMapName);
      local dashboardsVolumeMount = containerVolumeMount.new(dashboardsVolumeName, '/etc/grafana/provisioning/dashboards');

      local volumeMounts =
        [
          storageVolumeMount,
          datasourcesVolumeMount,
          dashboardsVolumeMount,
        ] +
        [
          local dashboardName = std.strReplace(name, '.json', '');
          containerVolumeMount.new('grafana-dashboard-' + dashboardName, '/grafana-dashboard-definitions/0/' + dashboardName)
          for name in std.objectFields($._config.grafana.dashboards)
        ] +
        [
          local dashboardName = std.strReplace(name, '.json', '');
          containerVolumeMount.new('grafana-dashboard-' + dashboardName, '/grafana-dashboard-definitions/0/' + dashboardName)
          for name in std.objectFields($._config.grafana.rawDashboards)
        ] +

        if std.length($._config.grafana.config) > 0 then [configVolumeMount] else [];

      local volumes =
        [
          storageVolume,
          datasourcesVolume,
          dashboardsVolume,
        ] +
        [
          local dashboardName = 'grafana-dashboard-' + std.strReplace(name, '.json', '');
          volume.withName(dashboardName) +
          volume.mixin.configMap.withName(dashboardName)
          for name in std.objectFields($._config.grafana.dashboards)
        ] +
        [
          local dashboardName = 'grafana-dashboard-' + std.strReplace(name, '.json', '');
          volume.withName(dashboardName) +
          volume.mixin.configMap.withName(dashboardName)
          for name in std.objectFields($._config.grafana.rawDashboards)
        ] +
        if std.length($._config.grafana.config) > 0 then [configVolume] else [];

      local plugins = (if std.length($._config.grafana.plugins) == 0 then {} else env.new('GF_INSTALL_PLUGINS', std.join(',', $._config.grafana.plugins)));

      local c =
        container.new('grafana', $._config.imageRepos.grafana + ':' + $._config.versions.grafana) +
        container.withEnv([
          env.new('GF_RENDERING_SERVER_URL', 'http://renderer:' + imageRendererPort + '/render'),
          env.new('GF_RENDERING_CALLBACK_URL', 'http://grafana:' + targetPort),
          plugins,
        ]) +
        container.withVolumeMounts(volumeMounts) +
        container.withPorts(containerPort.newNamed(targetPort, portName)) +
        container.mixin.readinessProbe.httpGet.withPath('/api/health') +
        container.mixin.readinessProbe.httpGet.withPort(portName) +
        container.mixin.resources.withRequests($._config.grafana.container.requests) +
        container.mixin.resources.withLimits($._config.grafana.container.limits);

      local i =
        container.new('grafana-image-renderer', $._config.imageRepos.grafanaImageRenderer + ':' + $._config.versions.grafanaImageRenderer) +
        container.withPorts(containerPort.newNamed(imageRendererPort, portName)) +
        container.mixin.resources.withRequests($._config.grafana.imageRendererContainer.requests) +
        container.mixin.resources.withLimits($._config.grafana.imageRendererContainer.limits);

      deployment.new('grafana', 1, [c, i], podLabels) +
      deployment.mixin.metadata.withNamespace($._config.namespace) +
      deployment.mixin.metadata.withLabels(podLabels) +
      deployment.mixin.spec.selector.withMatchLabels(podLabels) +
      deployment.mixin.spec.template.spec.withNodeSelector({ 'beta.kubernetes.io/os': 'linux' }) +
      deployment.mixin.spec.template.spec.withVolumes(volumes) +
      deployment.mixin.spec.template.spec.securityContext.withRunAsNonRoot(true) +
      deployment.mixin.spec.template.spec.securityContext.withRunAsUser(65534) +
      deployment.mixin.spec.template.spec.withServiceAccountName('grafana'),
  },
}
