#!/usr/bin/env bash
set -euo pipefail

REGION="us-east-1"

V1CS_NS="trendmicro-system"
V1CS_RELEASE="trendmicro"

V1FS_NS="visionone-file-security"
V1FS_RELEASE="visionone-file-security"

pause() { read -rp "Press ENTER to continue..."; }

ensure_helm() {
  if command -v helm &>/dev/null; then
    return
  fi

  echo "Helm not found. Installing..."
  curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
}

check_status() {
  echo ""
  echo "Lab status"
  echo "----------------------------"

  if helm status "$V1CS_RELEASE" -n "$V1CS_NS" &>/dev/null; then
    echo "✔ v1cs is INSTALLED"
  else
    echo "✖ v1cs is NOT installed"
  fi

  if helm status "$V1FS_RELEASE" -n "$V1FS_NS" &>/dev/null; then
    echo "✔ v1fs is INSTALLED"
  else
    echo "✖ v1fs is NOT installed"
  fi
}

### =========================
### V1CS
### =========================
create_v1cs_overrides() {
cat <<'EOF' > overrides.yaml
visionOne:
    bootstrapToken: V1CS-TOKEN
    endpoint: https://api.xdr.trendmicro.com/external/v2/direct/vcs/external/vcs
    exclusion:
        namespaces: [kube-system]
    runtimeSecurity:
        enabled: true
    vulnerabilityScanning:
        enabled: true
    malwareScanning:
        enabled: true
    secretScanning:
        enabled: true
    fileIntegrityMonitoring:
        enabled: true
EOF
}

deploy_v1cs() {
  ensure_helm
  create_v1cs_overrides

  helm install \
    "$V1CS_RELEASE" \
    --namespace "$V1CS_NS" --create-namespace \
    --values overrides.yaml \
    https://github.com/trendmicro/visionone-container-security-helm/archive/main.tar.gz
}

destroy_v1cs() {
  helm uninstall "$V1CS_RELEASE" -n "$V1CS_NS" || true
}

### =========================
### V1FS
### =========================
deploy_v1fs() {
  ensure_helm

  helm repo add trendmicro https://trendmicro.github.io/visionone-file-security-helm
  helm repo update

  helm install "$V1FS_RELEASE" trendmicro/visionone-file-security \
    --namespace "$V1FS_NS" --create-namespace \
    --set visionOne.apiKey='V1FS-TOKEN' \
    --set icap.enabled=true
}

destroy_v1fs() {
  helm uninstall "$V1FS_RELEASE" -n "$V1FS_NS" || true
}

show_v1fs_endpoint() {
  svc=$(kubectl get svc -n "$V1FS_NS" -o jsonpath='{.items[0].metadata.name}')
  ip=$(kubectl get svc "$svc" -n "$V1FS_NS" -o jsonpath='{.spec.clusterIP}')
  port=$(kubectl get svc "$svc" -n "$V1FS_NS" -o jsonpath='{.spec.ports[0].port}')

  echo "V1FS internal endpoint:"
  echo "http://${svc}.${V1FS_NS}.svc.cluster.local:${port}"
  echo "ClusterIP: ${ip}:${port}"
}

### =========================
### MENUS
### =========================
v1cs_menu() {
  echo "1) Deploy v1cs"
  echo "2) Destroy v1cs"
  echo "0) Back"
  read -rp "Choice: " c
  case "$c" in
    1) deploy_v1cs ;;
    2) destroy_v1cs ;;
  esac
}

v1fs_menu() {
  echo "1) Deploy v1fs (ICAP enabled)"
  echo "2) Destroy v1fs"
  echo "3) Show internal URL"
  echo "0) Back"
  read -rp "Choice: " c
  case "$c" in
    1) deploy_v1fs ;;
    2) destroy_v1fs ;;
    3) show_v1fs_endpoint ;;
  esac
}

### =========================
### MAIN MENU
### =========================
while true; do
  clear
  echo "=== Trend Labs Manager ==="
  echo "1) Check lab status"
  echo "2) v1cs lab"
  echo "3) v1fs lab"
  echo "4) Finish"
  read -rp "Select option: " opt

  case "$opt" in
    1) check_status; pause ;;
    2) v1cs_menu; pause ;;
    3) v1fs_menu; pause ;;
    4) exit 0 ;;
  esac
done
