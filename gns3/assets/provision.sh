#!/usr/bin/env bash
set -x

echo "Provision me!" >> /var/log/provision.log

echo "${GNS3_PORT}"
source /etc/gns3/provision.env

echo "${GNS3_PORT}"
