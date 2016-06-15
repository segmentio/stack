#!/usr/bin/env bash

modules=$(ls -1 */*.tf | xargs -I % dirname %)

(terraform validate . && echo "√ stack") || exit 1

for m in $modules; do
  (terraform validate $m && echo "√ $m") || exit 1
done
