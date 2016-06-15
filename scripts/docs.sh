#!/usr/bin/env bash

modules=$(ls -1 */*.tf | xargs -I % dirname %)

title(){
  local name="$1"
}

echo > docs.md

echo "Generating docs for stack"
printf "# Stack\n\n" >> docs.md
terraform-docs md . >> docs.md

for m in $modules; do
  if [[ "$m" != "iam-role" ]]; then
    echo "generating docs for $m"
    printf "# $m\n\n" >> docs.md
    terraform-docs md $m >> docs.md
  fi
done
