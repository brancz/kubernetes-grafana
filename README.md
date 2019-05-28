# Kubernetes Grafana

This project is about running [Grafana](https://grafana.com/) on [Kubernetes](https://kubernetes.io/) with [Prometheus](https://prometheus.io/) as the datasource in a very opinionated and entirely declarative way. This allows easily operating Grafana highly available as if it was a stateless application - no need to run a clustered database for your dashboarding solution anymore!

Note that at this point this is primarily about getting into the same state as [kube-prometheus](https://github.com/coreos/prometheus-operator/tree/master/contrib/kube-prometheus) currently is. It is about packaging up Grafana as a reusable component, without dashboards. Dashboards are to be defined when using this Grafana package.

## What and why is happening here?

This repository exists because the Grafana stack in [kube-prometheus](https://github.com/coreos/prometheus-operator/tree/master/contrib/kube-prometheus) has gotten close to unmaintainable due to the many steps of generation and it's a very steep learning curve for newcomers.

Since Grafana v5, Grafana can be provisioned with dashboards from files. This project is primarily about generating a set of useful Grafana dashboards for use with and on Kubernetes using with Prometheus as the datasource.

In this repository everything is generated via jsonnet:

* The [Grafana dashboard sources configuration](https://github.com/brancz/kubernetes-grafana/blob/master/grafana/configs/dashboard-sources/dashboards.libsonnet).
* The Grafana dashboard datasource configuration, is part of the [configuration](https://github.com/brancz/kubernetes-grafana/blob/master/grafana/grafana.libsonnet#L17-L25), and is then simply [rendered to json](https://github.com/brancz/kubernetes-grafana/blob/master/grafana/grafana.libsonnet#L47).
* The Grafana dashboard definitions are defined as part of the [configuration](https://github.com/brancz/kubernetes-grafana/blob/master/grafana/grafana.libsonnet#L29). For example, dashboard definitions can be developed with the help of [grafana/grafonnet-lib](https://github.com/grafana/grafonnet-lib).
* The [Grafana Kubernetes manifests](https://github.com/brancz/kubernetes-grafana/tree/master/grafana) with the help of [ksonnet/ksonnet-lib](https://github.com/ksonnet/ksonnet-lib).

With a single jsonnet command the whole stack is generated and can be applied against a Kubernetes cluster.

## Prerequisites

You need a running Kubernetes cluster in order to try this out, with the kube-prometheus stack deployed on it as have Docker installed to and be able to mount volumes correctly (this is **not** the case when using the Docker host of minikube).

For trying this out provision [minikube](https://github.com/kubernetes/minikube) with these settings:

```
minikube start --kubernetes-version=v1.9.3 --memory=4096 --bootstrapper=kubeadm --extra-config=kubelet.authentication-token-webhook=true --extra-config=kubelet.authorization-mode=Webhook --extra-config=scheduler.address=0.0.0.0 --extra-config=controller-manager.address=0.0.0.0
```

## Usage

Use this package in your own infrastructure using [`jsonnet-bundler`](https://github.com/jsonnet-bundler/jsonnet-bundler):

```
jb install github.com/brancz/kubernetes-grafana/grafana
```

An example of how to use it could be:

[embedmd]:# (examples/basic.jsonnet)
```jsonnet
local k = import 'ksonnet/ksonnet.beta.3/k.libsonnet';
local service = k.core.v1.service;
local servicePort = k.core.v1.service.mixin.spec.portsType;

local grafana = ((import 'grafana/grafana.libsonnet') + {
                   _config+:: {
                     namespace: 'monitoring-grafana',
                   },
                 }).grafana;

k.core.v1.list.new(
  [
    grafana.dashboardDefinitions,
    grafana.dashboardSources,
    grafana.dashboardDatasources,
    grafana.deployment,
    grafana.serviceAccount,
    grafana.service +
    service.mixin.spec.withPorts(servicePort.newNamed('http', 3000, 'http') + servicePort.withNodePort(30910)) +
    service.mixin.spec.withType('NodePort'),
  ]
)
```

This builds the entire Grafana stack with your own dashboards and a configurable namespace.

Simply run:

```
$ jsonnet -J vendor example.jsonnet
```

### Customizing

#### Adding dashboards

This setup is optimized to work best when Grafana is used declaratively, so when adding dashboards they are added declaratively as well. In jsonnet there are libraries available to avoid having to repeat boilerplate of Grafana dashboard json. An example with the [grafana/grafonnet-lib](https://github.com/grafana/grafonnet-lib):

[embedmd]:# (examples/dashboard-definition.jsonnet)
```jsonnet
local k = import 'ksonnet/ksonnet.beta.3/k.libsonnet';
local service = k.core.v1.service;
local servicePort = k.core.v1.service.mixin.spec.portsType;

local grafana = import 'grafonnet/grafana.libsonnet';
local dashboard = grafana.dashboard;
local row = grafana.row;
local prometheus = grafana.prometheus;
local template = grafana.template;
local graphPanel = grafana.graphPanel;

local grafana =
  ((import 'grafana/grafana.libsonnet') +
   {
     _config+:: {
       namespace: 'monitoring-grafana',
       grafana+:: {
         dashboards+:: {
           'my-dashboard.json':
             dashboard.new('My Dashboard')
             .addTemplate(
               {
                 current: {
                   text: 'Prometheus',
                   value: 'Prometheus',
                 },
                 hide: 0,
                 label: null,
                 name: 'datasource',
                 options: [],
                 query: 'prometheus',
                 refresh: 1,
                 regex: '',
                 type: 'datasource',
               },
             )
             .addRow(
               row.new()
               .addPanel(graphPanel.new('My Panel', span=6, datasource='$datasource')
                         .addTarget(prometheus.target('vector(1)')))
             ),
         },
       },
     },
   }).grafana;

k.core.v1.list.new(
  [
    grafana.dashboardDefinitions,
    grafana.dashboardSources,
    grafana.dashboardDatasources,
    grafana.deployment,
    grafana.serviceAccount,
    grafana.service +
    service.mixin.spec.withPorts(servicePort.newNamed('http', 3000, 'http') + servicePort.withNodePort(30910)) +
    service.mixin.spec.withType('NodePort'),
  ]
)
```

#### Dashboards mixins

Using the [kubernetes-mixin](https://github.com/kubernetes-monitoring/kubernetes-mixin)s, simply install:

```
$ jb install github.com/kubernetes-monitoring/kubernetes-mixin
```

And apply the mixin:

[embedmd]:# (examples/basic-with-mixin.jsonnet)
```jsonnet
local k = import 'ksonnet/ksonnet.beta.3/k.libsonnet';
local service = k.core.v1.service;
local servicePort = k.core.v1.service.mixin.spec.portsType;

local grafana = (
  (import 'grafana/grafana.libsonnet') +
  (import 'kubernetes-mixin/mixin.libsonnet') +
  {
    _config+:: {
      namespace: 'monitoring-grafana',
      grafana+:: {
        dashboards: $.grafanaDashboards,
      },
    },
  }
).grafana;

k.core.v1.list.new(
  [
    grafana.dashboardDefinitions,
    grafana.dashboardSources,
    grafana.dashboardDatasources,
    grafana.deployment,
    grafana.serviceAccount,
    grafana.service +
    service.mixin.spec.withPorts(servicePort.newNamed('http', 3000, 'http') + servicePort.withNodePort(30910)) +
    service.mixin.spec.withType('NodePort'),
  ]
)
```

To generate, again simply run:

```
$ jsonnet -J vendor example-with-mixin.jsonnet
```

This yields a fully configured Grafana stack with useful Kubernetes dashboards.

#### Config customization

Grafana can be run with many different configurations. Different organizations have different preferences, therefore the Grafana configuration can be arbitrary modified. The configuration happens via the the `$._config.grafana.config` variable. The `$._config.grafana.config` field is compiled using jsonnet's `std.manifestIni` function. Additionally you can specify your organizations' LDAP configuration through `$._config.grafana.ldap` variable.

For example to modify Grafana configuration and set up LDAP use:

[embedmd]:# (examples/custom-ini.jsonnet)
```jsonnet
local k = import 'ksonnet/ksonnet.beta.3/k.libsonnet';
local service = k.core.v1.service;
local servicePort = k.core.v1.service.mixin.spec.portsType;

local grafana = ((import 'grafana/grafana.libsonnet') + {
                   _config+:: {
                     namespace: 'monitoring-grafana',
                     grafana+:: {
                       config: {
                         sections: {
                           metrics: { enabled: true },
                           'auth.ldap': {
                             enabled: true,
                             config_file: '/etc/grafana/ldap.toml',
                             allow_sign_up: true,
                           },
                         },
                       },
                       ldap: |||
                         [[servers]]
                         host = "127.0.0.1"
                         port = 389
                         use_ssl = false
                         start_tls = false
                         ssl_skip_verify = false

                         bind_dn = "cn=admin,dc=grafana,dc=org"
                         bind_password = 'grafana'

                         search_filter = "(cn=%s)"

                         search_base_dns = ["dc=grafana,dc=org"]
                       |||,
                     },
                   },
                 }).grafana;

k.core.v1.list.new(
  [
    grafana.dashboardDefinitions,
    grafana.config,
    grafana.dashboardSources,
    grafana.dashboardDatasources,
    grafana.deployment,
    grafana.serviceAccount,
    grafana.service +
    service.mixin.spec.withPorts(servicePort.newNamed('http', 3000, 'http') + servicePort.withNodePort(30910)) +
    service.mixin.spec.withType('NodePort'),
  ]
)
```

#### Plugins

The config object allows specifying an array of plugins to install at startup.

[embedmd]:# (examples/plugins.jsonnet)
```jsonnet
local k = import 'ksonnet/ksonnet.beta.3/k.libsonnet';
local service = k.core.v1.service;
local servicePort = k.core.v1.service.mixin.spec.portsType;

local grafana = ((import 'grafana/grafana.libsonnet') + {
                   _config+:: {
                     namespace: 'monitoring-grafana',
                     grafana+:: {
                       plugins: ['camptocamp-prometheus-alertmanager-datasource'],
                     },
                   },
                 }).grafana;

k.core.v1.list.new(
  [
    grafana.dashboardDefinitions,
    grafana.dashboardSources,
    grafana.dashboardDatasources,
    grafana.deployment,
    grafana.serviceAccount,
    grafana.service +
    service.mixin.spec.withPorts(servicePort.newNamed('http', 3000, 'http') + servicePort.withNodePort(30910)) +
    service.mixin.spec.withType('NodePort'),
  ]
)
```

# Roadmap

There are a number of things missing for the Grafana stack and tooling to be fully migrated.

**If you are interested in working on any of these, please open a respective issue to avoid duplicating efforts.**

1. A tool to review Grafana dashboard changes on PRs. While reviewing jsonnet code is a lot easier than the large Grafana json sources, it's hard to imagine what that will actually end up looking like once rendered. Ideally a production-like environment is spun up and produces metrics to be graphed, then a tool could take a screenshot and [Grafana snapshot](http://docs.grafana.org/plugins/developing/snapshot-mode/) of the rendered Grafana dashboards. That way the changes can not only be reviewed in code but also visually. Similar to point 2 this should eventually be it's own project.
