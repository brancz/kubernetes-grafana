fmt:
	@echo -e "\033[1m>> Formatting all jsonnet files\033[0m"
	find -iname '*.libsonnet' | awk '{print $1}' | xargs jsonnet fmt -i $1

generate: fmt docs
	git diff --exit-code

docs: embedmd
	@echo -e "\033[1m>> Generating docs\033[0m"
	embedmd -w README.md

embedmd:
	@echo -e "\033[1m>> Ensuring embedmd is installed\033[0m"
	go get github.com/campoy/embedmd

build: jb
	cd grafana && jb install
	$(MAKE) compile

compile:
	jsonnet -J grafana/vendor example.jsonnet

jb:
	@echo -e "\033[1m>> Ensuring jb (jsonnet-bundler) is installed\033[0m"
	go get github.com/jsonnet-bundler/jsonnet-bundler/cmd/jb
