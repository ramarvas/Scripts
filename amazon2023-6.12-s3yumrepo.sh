#!/bin/bash
set -e
##
## Enhanced method for synchronizing the RMP repository with S3 buckets. Based on Midhun Nemani's work.
## Last update: 08/08/2025
##
INFO="\e[1;94m"
ERROR="\e[1;31m"
NC="\e[0m"
#This script Supports only amazon2023
os=amazon2023
s3path='bb-os-repo/Amazon'
slackurl='https://hooks.slack.com/services/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'
[ ! -d  /repo/$os ] && sudo mkdir -p /repo/$os
if [[ $(df -H . | grep /repo | awk '{print $5}' | cut -d'%' -f1) -gt 90 ]]; then
  echo -e "${ERROR} Error: Insufficient disk space. Clean /repos/$os path${NC}"
  exit 1
fi
latestkernel=$(sudo dnf upgrade  2>&1 | grep -oP '(?<=releasever=)[^ ]+' | sort -r | tail -1 | tr -d '\n')
echo -e "${INFO}Latest Kernel version available: $latestkernel${NC}"
version=$latestkernel
if [[ -d /repo/$os/$version ]]; then
  echo -e "${ERROR}Error: /repo/$os/$version directory found. Remove directory if needed ${NC}"
  exit 1
fi
sudo mkdir -p /repo/$os/$version
# Sync locally remote repo
reposList="amazonlinux kernel-livepatch puppet8"
for repo in $reposList; do
  sudo dnf reposync -n -g -p /repo/$os/$version --repoid=$repo
  sudo createrepo -v /repo/$os/$version/$repo
done
# sync whole folder to your S3 bucket
aws s3 sync --acl public-read --follow-symlinks --delete /repo/$os/$version/ s3://$s3path/$version/
#Notify
curl -X POST --data-urlencode 'payload={"channel": "#techops-housekeeping", "text": "New OS Patch has been published : '$os/$version'", "icon_emoji": ":postal_horn"}' $slackurl
##Laurencio
