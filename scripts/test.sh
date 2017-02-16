#!/usr/bin/env bash

modules=$(find -mindepth 2 -name *.tf -printf '%P\n' | xargs -I % dirname %)

(terraform validate . && echo "√ stack") || exit 1

for m in $modules; do
  (terraform validate $m && echo "√ $m") || exit 1
done
