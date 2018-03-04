local grafana = import "grafonnet/grafana.libsonnet";
local singlestat = grafana.singlestat;
local prometheus = grafana.prometheus;

{
    new(title, query)::
        singlestat.new(
            title,
            datasource="prometheus",
            span=3,
            valueName="current",
            valueMaps=[
                {
                      "op": "=",
                      "text": "0",
                      "value": "null"
                },
            ],
        )
        .addTarget(
            prometheus.target(
                query
            )
        ) + {
            withTextNullValue(text):: self {
                    valueMaps: [
                        {
                              "op": "=",
                              "text": text,
                              "value": "null",
                        },
                    ],
                },
            withSpanSize(size):: self {
                    span: size,
                }
        }
}
