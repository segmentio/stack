#!/bin/bash
set -e

systemctl daemon-reload
systemctl enable bootstrap.service
