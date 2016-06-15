#!/bin/bash
set -e

systemctl daemon-reload
systemctl enable ecs-agent.service
systemctl enable ecs-logs.service
