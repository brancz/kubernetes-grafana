SHELL=/bin/bash -o pipefail

all: build generate

fmt:
	@echo -e "\033[1m>> Formatting all jsonnet files\033[0m"
	find . -name 'vendor' -prune -o -name '*.libsonnet' -print -o -name '*.jsonnet' -print | xargs -n 1 -- jsonnetfmt -i

generate: fmt docs
	git diff --exit-code

docs: embedmd
	@echo -e "\033[1m>> Generating docs\033[0m"
	embedmd -w README.md

embedmd:
	@echo -e "\033[1m>> Ensuring embedmd is installed\033[0m"
	go install github.com/campoy/embedmd@latest

build: jb
	cd grafana && jb install
	$(MAKE) compile

compile:
	jsonnet -J grafana/vendor -J . examples/basic.jsonnet

jb:
	@echo -e "\033[1m>> Ensuring jb (jsonnet-bundler) is installed\033[0m"
	go install github.com/jsonnet-bundler/jsonnet-bundler/cmd/jb@latest
