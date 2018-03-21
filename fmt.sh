#!/usr/bin/env sh

echo -e "\033[1m>> Formatting all jsonnet files\033[0m"

find -iname '*.jsonnet' | awk '{print $1}' | xargs jsonnet fmt -i $1
