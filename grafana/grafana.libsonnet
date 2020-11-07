{
  _config+:: {
    namespace: 'default',

    versions+:: {
      grafana: '6.6.0',
    },

    imageRepos+:: {
      grafana: 'grafana/grafana',
    },

    prometheus+:: {
      name: 'k8s',
      serviceName: 'prometheus-' + $._config.prometheus.name,
    },

    grafana+:: {
      dashboards: {},
      rawDashboards: {},
      folderDashboards: {},
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
      env: [],
      port: 3000,
      resources: {
        requests: { cpu: '100m', memory: '100Mi' },
        limits: { cpu: '200m', memory: '200Mi' },
      },
      containers: [],
    },
  },
  grafanaDashboards: {},
  grafana+: {
    [if std.length($._config.grafana.config) > 0 then 'config']:
      {
        apiVersion: 'v1',
        kind: 'Secret',
        metadata: {
          name: 'grafana-config',
          namespace: $._config.namespace,
        },
        type: 'Opaque',
        data: {
                'grafana.ini': std.base64(std.encodeUTF8(std.manifestIni($._config.grafana.config))),
              } +
              if $._config.grafana.ldap != null then { 'ldap.toml': std.base64(std.encodeUTF8($._config.grafana.ldap)) } else {},
      },
    dashboardDefinitions:
      [
        {
          local dashboardName = 'grafana-dashboard-' + std.strReplace(name, '.json', ''),
          apiVersion: 'v1',
          kind: 'ConfigMap',
          metadata: {
            name: dashboardName,
            namespace: $._config.namespace,
          },
          data: { [name]: std.manifestJsonEx($._config.grafana.dashboards[name], '    ') },
        }
        for name in std.objectFields($._config.grafana.dashboards)
      ] + [
        {
          local dashboardName = 'grafana-dashboard-' + std.strReplace(name, '.json', ''),
          apiVersion: 'v1',
          kind: 'ConfigMap',
          metadata: {
            name: dashboardName,
            namespace: $._config.namespace,
          },
          data: { [name]: std.manifestJsonEx($._config.grafana.folderDashboards[folder][name], '    ') },
        }
        for folder in std.objectFields($._config.grafana.folderDashboards)
        for name in std.objectFields($._config.grafana.folderDashboards[folder])
      ] + (
        if std.length($._config.grafana.rawDashboards) > 0 then
          [

            {
              local dashboardName = 'grafana-dashboard-' + std.strReplace(name, '.json', ''),
              apiVersion: 'v1',
              kind: 'ConfigMap',
              metadata: {
                name: dashboardName,
                namespace: $._config.namespace,
              },
              data: { [name]: $._config.grafana.rawDashboards[name] },
            }
            for name in std.objectFields($._config.grafana.rawDashboards)
          ]
        else
          []
      ),
    dashboardSources:
      local dashboardSources = {
        apiVersion: 1,
        providers:
          (
            if std.length($._config.grafana.dashboards) +
               std.length($._config.grafana.rawDashboards) > 0 then [
              {
                name: '0',
                orgId: 1,
                folder: 'Default',
                type: 'file',
                options: {
                  path: '/grafana-dashboard-definitions/0',
                },
              },
            ] else []
          ) +
          [
            {
              name: folder,
              orgId: 1,
              folder: folder,
              type: 'file',
              options: {
                path: '/grafana-dashboard-definitions/' + folder,
              },
            }
            for folder in std.objectFields($._config.grafana.folderDashboards)
          ],
      };

      {
        kind: 'ConfigMap',
        apiVersion: 'v1',
        metadata: {
          name: 'grafana-dashboards',
          namespace: $._config.namespace,
        },
        data: { 'dashboards.yaml': std.manifestJsonEx(dashboardSources, '    ') },
      },
    dashboardDatasources:
      {
        apiVersion: 'v1',
        kind: 'Secret',
        metadata: {
          name: 'grafana-datasources',
          namespace: $._config.namespace,
        },
        type: 'Opaque',
        data: { 'datasources.yaml': std.base64(std.encodeUTF8(std.manifestJsonEx({
          apiVersion: 1,
          datasources: $._config.grafana.datasources,
        }, '    '))) },
      },
    service:
      {
        apiVersion: 'v1',
        kind: 'Service',
        metadata: {
          name: 'grafana',
          namespace: $._config.namespace,
          labels: {
            app: 'grafana',
          },
        },
        spec: {
          selector: $.grafana.deployment.spec.selector.matchLabels,
          type: 'NodePort',
          ports: [
            { name: 'http', targetPort: 'http', port: 3000 },
          ],
        },
      },
    serviceAccount:
      {
        apiVersion: 'v1',
        kind: 'ServiceAccount',
        metadata: {
          name: 'grafana',
          namespace: $._config.namespace,
        },
      },
    deployment:
      local targetPort = $._config.grafana.port;
      local portName = 'http';
      local podLabels = { app: 'grafana' };

      local configVolumeName = 'grafana-config';
      local configSecretName = 'grafana-config';
      local configVolume = { name: configVolumeName, secret: { secretName: configSecretName } };
      local configVolumeMount = { name: configVolumeName, mountPath: '/etc/grafana', readOnly: false };

      local storageVolumeName = 'grafana-storage';
      local storageVolume = { name: storageVolumeName, emptyDir: {} };
      local storageVolumeMount = { name: storageVolumeName, mountPath: '/var/lib/grafana', readOnly: false };

      local datasourcesVolumeName = 'grafana-datasources';
      local datasourcesSecretName = 'grafana-datasources';
      local datasourcesVolume = { name: datasourcesVolumeName, secret: { secretName: datasourcesSecretName } };
      local datasourcesVolumeMount = { name: datasourcesVolumeName, mountPath: '/etc/grafana/provisioning/datasources', readOnly: false };

      local dashboardsVolumeName = 'grafana-dashboards';
      local dashboardsConfigMapName = 'grafana-dashboards';
      local dashboardsVolume = { name: dashboardsVolumeName, configMap: { name: dashboardsConfigMapName } };
      local dashboardsVolumeMount = { name: dashboardsVolumeName, mountPath: '/etc/grafana/provisioning/dashboards', readOnly: false };

      local volumeMounts =
        [
          storageVolumeMount,
          datasourcesVolumeMount,
          dashboardsVolumeMount,
        ] +
        [
          {
            local dashboardName = std.strReplace(name, '.json', ''),
            name: 'grafana-dashboard-' + dashboardName,
            mountPath: '/grafana-dashboard-definitions/0/' + dashboardName,
            readOnly: false,
          }
          for name in std.objectFields($._config.grafana.dashboards)
        ] +
        [
          {
            local dashboardName = std.strReplace(name, '.json', ''),
            name: 'grafana-dashboard-' + dashboardName,
            mountPath: '/grafana-dashboard-definitions/' + folder + '/' + dashboardName,
            readOnly: false,
          }
          for folder in std.objectFields($._config.grafana.folderDashboards)
          for name in std.objectFields($._config.grafana.folderDashboards[folder])
        ] +
        [
          {

            local dashboardName = std.strReplace(name, '.json', ''),
            name: 'grafana-dashboard-' + dashboardName,
            mountPath: '/grafana-dashboard-definitions/0/' + dashboardName,
            readOnly: false,
          }
          for name in std.objectFields($._config.grafana.rawDashboards)
        ] + (
          if std.length($._config.grafana.config) > 0 then [configVolumeMount] else []
        );

      local volumes =
        [
          storageVolume,
          datasourcesVolume,
          dashboardsVolume,
        ] +
        [
          {
            local dashboardName = 'grafana-dashboard-' + std.strReplace(name, '.json', ''),
            name: dashboardName,
            configMap: { name: dashboardName },
          }
          for name in std.objectFields($._config.grafana.dashboards)
        ] +
        [
          {
            local dashboardName = 'grafana-dashboard-' + std.strReplace(name, '.json', ''),
            name: dashboardName,
            configMap: { name: dashboardName },
          }
          for folder in std.objectFields($._config.grafana.folderDashboards)
          for name in std.objectFields($._config.grafana.folderDashboards[folder])
        ] +
        [
          {
            local dashboardName = 'grafana-dashboard-' + std.strReplace(name, '.json', ''),
            name: dashboardName,
            configMap: { name: dashboardName },
          }
          for name in std.objectFields($._config.grafana.rawDashboards)
        ] +
        if std.length($._config.grafana.config) > 0 then [configVolume] else [];

      local plugins = (
        if std.length($._config.grafana.plugins) == 0 then
          []
        else
          [{ name: 'GF_INSTALL_PLUGINS', value: std.join(',', $._config.grafana.plugins) }]
      );

      local c = [{
        name: 'grafana',
        image: $._config.imageRepos.grafana + ':' + $._config.versions.grafana,
        env: $._config.grafana.env + plugins,
        volumeMounts: volumeMounts,
        ports: [{ name: portName, containerPort: targetPort }],
        readinessProbe: {
          httpGet: { path: '/api/health', port: portName },
        },
        resources: $._config.grafana.resources,
      }] + $._config.grafana.containers;

      {
        apiVersion: 'apps/v1',
        kind: 'Deployment',
        metadata: {
          name: 'grafana',
          namespace: $._config.namespace,
          labels: podLabels,
        },
        spec: {
          replicas: 1,
          selector: {
            matchLabels: podLabels,
          },
          template: {
            metadata: {
              labels: podLabels,
              annotations: {
                [if std.length($._config.grafana.config) > 0 then 'checksum/grafana-config']: std.md5(std.toString($.grafana.config)),
                'checksum/grafana-datasources': std.md5(std.toString($.grafana.dashboardDatasources)),
              },
            },
            spec: {
              containers: c,
              volumes: volumes,
              serviceAccountName: $.grafana.serviceAccount.metadata.name,
              nodeSelector: { 'beta.kubernetes.io/os': 'linux' },
              securityContext: { fsGroup: 65534, runAsNonRoot: true, runAsUser: 65534 },
            },
          },
        },
      },
  },
}
