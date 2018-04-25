FROM golang:1.10-alpine

RUN apk add --update git

RUN go get -u github.com/brancz/gojsontoyaml && \
    go get -u github.com/jsonnet-bundler/jsonnet-bundler/cmd/jb && \
    go get -u github.com/fatih/color && \
    go get github.com/google/go-jsonnet && \
    cd /go/src/github.com/google/go-jsonnet/jsonnet && \
    go build -o /go/bin/jsonnet

RUN mkdir -p /go/src/github.com/brancz/kubernetes-grafana
ADD jsonnetfile.json /go/src/github.com/brancz/kubernetes-grafana/jsonnetfile.json
RUN cd /go/src/github.com/brancz/kubernetes-grafana && jb install

WORKDIR /go/src/github.com/brancz/kubernetes-grafana
