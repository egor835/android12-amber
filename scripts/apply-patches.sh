#!/bin/bash
# Apply android12-amber patches onto a synced lineage-19.1 tree.
# Usage: scripts/apply-patches.sh /path/to/lineage-19.1
set -e
TOP=${1:?usage: $0 /path/to/lineage-19.1}
HERE=$(cd "$(dirname "$0")/.." && pwd)
declare -A DIRS=(
  [kernel_yandex_sdm660]=kernel/yandex/sdm660
  [vendor_yandex]=vendor/yandex
  [system_bpf]=system/bpf
  [system_netd]=system/netd
)
for name in "${!DIRS[@]}"; do
  dir=$TOP/${DIRS[$name]}
  echo "==> $name -> ${DIRS[$name]}"
  git -C "$dir" -c user.name=amber -c user.email=amber@localhost am -3 "$HERE"/patches/$name/*.patch
done
echo "All patches applied."
