#!/bin/bash
set -euo pipefail
KUBEADM_CONFIG="${1-/tmp/kubeadm.yaml}"
echo "Printing to $KUBEADM_CONFIG"

if [ -d "$KUBEADM_CONFIG" ]; then
    echo "$KUBEADM_CONFIG is a directory!"
    exit 1
fi

if [ ! -d $(dirname "$KUBEADM_CONFIG") ]; then
    echo "please create directory $(dirname $KUBEADM_CONFIG)"
    exit 1
fi

if [ ! $(which yq) ]; then
    echo "please install yq"
    exit 1
fi

if [ ! $(which kubeadm) ]; then
    echo "please install kubeadm"
    exit 1
fi

INTERNAL_IP="${2-10.255.255.101}"

kubeadm config print init-defaults --component-configs=KubeletConfiguration > "$KUBEADM_CONFIG"
yq -i eval 'select(.nodeRegistration.criSocket) |= .nodeRegistration.criSocket = "unix:///var/run/crio/crio.sock"' "$KUBEADM_CONFIG"
yq -i eval "select(.localAPIEndpoint.advertiseAddress) |= .localAPIEndpoint.advertiseAddress = \"$INTERNAL_IP\"" "$KUBEADM_CONFIG"
yq -i eval "select(.networking) += {\"podSubnet\":  \"10.32.0.0/12\"}" "$KUBEADM_CONFIG"
yq -i eval 'select(di == 1) |= .cgroupDriver = "systemd"' "$KUBEADM_CONFIG"
