#!/usr/bin/env bash
set -euo pipefail

### =================================================
### GLOBAL CONFIG
### =================================================
V1CS_NS="trendmicro-system"
V1CS_RELEASE="trendmicro"

V1FS_NS="visionone-filesecurity"
V1FS_RELEASE="v1fs"

# --- V1FS REGISTRATION TOKEN (embedded, no prompt) ---
V1FS_REGISTRATION_TOKEN="eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1NiJ9.eyJjaWQiOiJjYjM3YmU2Mi0zMzJjLTQ4NjctYWFkOC0xZDVkODE3NDYzMjYiLCJjcGlkIjoic3ZwIiwicHBpZCI6InNmcyIsIml0IjoxNzcxNDcxNzgwLCJ1aWQiOiIiLCJwbCI6IntcImRvbWFpblwiOiBcImFwaS54ZHIudHJlbmRtaWNyby5jb21cIn0iLCJldCI6MTc3MjA3NjU4MCwiZGlkIjoiMDAwMDAwMDAtMDAwMC0wMDAwLTAwMDAtMDAwMDAwMDAwMDAwIiwidG9rZW5Vc2UiOiJkZXZpY2UifQ.fTNAWuqchTWNVVsjLFIHQnAknsnLynz7U4I6s6BDPOwihGQ5cuoyWurFeRJdKKV6MWx9J3r7EB4pLq7jiFEbtd8R1Jjn-itwf1ic8Baqm7Qo2CPHr-tZmscrqUoRKj1KuMOTUBTFQ6W6K9tPPI7wyGxPPRk28RNqrexkU9mW_A_PrwdfHrioUnTuH3kJ8u9oC93JFeO5c9l-igaXpZwUCmZcWj9iDr0eku-xdi8QeoDCLNrGAcPdi1oogTg7TSCmvLLIbAae_eHKgWaVb9r2GxuPEpIOxbYFVCCx2WIY2kOfnsN_bRtVwsKFOSU6rEwBMrYGHRwT-5Wq76ppmLPfMd6aG--wkS4vk3uNRk-JvbNdg2IQQjc1RbX28APva5B0nFq43As42jyWnl9uZdCruGLG4vFVlkaMOGH27HyiI6IRCxASRC8cWVn-aCkVBi4gulzWuOfxnsjigvdd2t4xB7D67kjUMb6Dm2-MeJTmmTM7SaBoNECE0qV3fKf5XEHAparTbOiAoCcL7IOQErswDwl9zhBPnhRvoRCs6n6QhQdm_ba6DwHSFb3mcGSQ-Q_9qFYECxGaK7tSaolxLhBRz3FxTqIT42mkqGzRPaj8-qnwpM3xC7217Sp2GpFaVpVwzcaJeDuQrJJs2uW9d4SDz9Hy4ZjdyRPpq3uf8WgiUCU"

pause() { read -rp "Press ENTER to continue..."; }

### =================================================
### HELM CHECK
### =================================================
ensure_helm() {
  if command -v helm &>/dev/null; then
    return
  fi

  echo "Helm not found. Installing Helm..."
  curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
}

### =================================================
### STATUS CHECK
### =================================================
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

### =================================================
### V1CS (unchanged)
### =================================================
create_v1cs_overrides() {
cat <<'EOF' > overrides.yaml
visionOne:
    bootstrapToken: eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1NiJ9.eyJjaWQiOiJjYjM3YmU2Mi0zMzJjLTQ4NjctYWFkOC0xZDVkODE3NDYzMjYiLCJjcGlkIjoic3ZwIiwicHBpZCI6InZjcyIsIml0IjoxNzcxNDcxNDkzLCJ1aWQiOiIiLCJwbCI6IjM5czRZbTJONHlPM1JjTXE1QUxWeDkzSDlaZSIsImV0IjoxNzcxNTU3ODkzLCJkaWQiOiJLaGF6YWREdW0tMzlzNFlnYUdCSGhZNjNqNFFjRUlFZlFKcHFtIiwidG9rZW5Vc2UiOiJkZXZpY2UifQ.XUoAwJyEYbgCwdxQEnp5WJOQ0pBi7mQ22zqypCO_7wcE8zLzVirh-R8Puzc2RsBdAMeImB7rV0VsQFyqJHNof_vU96wrJ-73NLSN8AnGuQsKhyYBLGpcWlQtsNT0Oj6jyTIiGGbAILcsWRg79tYhQtFbzHv5vWw2FswIWb2gjVx04MoZ8SLltADs0HBEd2-9F4ILJH2pgcZJQFUmpn_wKM2mue0IwsuvSw7FWJit6FteihLXQtEa_NBKnNb_22wRWF5gm2U9v59WnIscjEapkw4yM_OHSs7nXDJVDHlLLz9d8XUd4ddOHBOwSKlS7fTNJ4GL-Q_Bww7K9CKVz36G4pT8S6a0I2zZcppCCqCs1eSWOcdMNcUml93wBpckLC385Pjq5_RfbeQobrbYNt2C1XVD9Rk8YBvltq8lMMG4-KSCa5ZBuoLu1YGDrwJe5ZOvgcIPi8UH5VcHSDP5Lp-1PIjD3kgljbtQnNyinfTn1-kPvFWDDOT0Sxhrbqhsznysimrefej725O82d_muIawvsVcNVZ75pMAMsKgFGcXMtsqKW3tQ5KiZa_MNDfASMu6AvYidGw7Z--J3XlqWEm4bNqbr3kldQmyUGvK_qBuJ_nuENjzJe5e8pRsrLKDT40yaAtxSroOpmkmSvslyeQbOZycwz4BmENdNxtGP2tm2BE
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

### =================================================
### V1FS (CORRECT & NON-INTERACTIVE)
### =================================================
deploy_v1fs() {
  ensure_helm

  kubectl create namespace "$V1FS_NS" 2>/dev/null || true

  kubectl create secret generic token-secret \
    --from-literal=registration-token="$V1FS_REGISTRATION_TOKEN" \
    -n "$V1FS_NS" 2>/dev/null || true

  kubectl create secret generic device-token-secret \
    -n "$V1FS_NS" 2>/dev/null || true

  helm repo add visionone-filesecurity https://trendmicro.github.io/visionone-file-security-helm/ 2>/dev/null || true
  helm repo update

  helm install "$V1FS_RELEASE" \
    visionone-filesecurity/visionone-filesecurity \
    -n "$V1FS_NS"
}

destroy_v1fs() {
  helm uninstall "$V1FS_RELEASE" -n "$V1FS_NS" || true
}

show_v1fs_endpoint() {
  echo ""
  echo "V1FS internal endpoints:"
  echo "ICAP : icap://${V1FS_RELEASE}-visionone-filesecurity-scanner:1344"
  echo "gRPC : ${V1FS_RELEASE}-visionone-filesecurity-scanner:50051"
}

### =================================================
### MENUS
### =================================================
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
  echo "1) Deploy v1fs (ICAP scanner)"
  echo "2) Destroy v1fs"
  echo "3) Show ICAP / gRPC internal endpoints"
  echo "0) Back"
  read -rp "Choice: " c
  case "$c" in
    1) deploy_v1fs ;;
    2) destroy_v1fs ;;
    3) show_v1fs_endpoint ;;
  esac
}

### =================================================
### MAIN MENU
### =================================================
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
