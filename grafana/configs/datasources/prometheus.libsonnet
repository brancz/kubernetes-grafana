{
    datasources: [
        {
            name: "prometheus",
            type: "prometheus",
            access: "proxy",
            org_id: 1,
            url: "http://prometheus-k8s.monitoring.svc:9090",
            version: 1,
            etitable: false,
        },
    ],
}
