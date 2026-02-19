#!/usr/bin/env bash
set -euo pipefail

### =========================
### CONFIGURATION
### =========================
CLUSTER_NAME="eks-lab"
REGION="us-east-1"
ACCOUNT_ID="195216432632"
ECR="${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com"

declare -A APPS
APPS[v1fs-icap]="8080 ${ECR}/demo-v1fs-icap /icap-scan-web python3 app.py"
APPS[trendai]="8000 ${ECR}/tools-ai-sec-demo"
APPS[malware-samples]="80 ${ECR}/tools-malware-samples"

### =========================
### UTILITIES
### =========================
pause() { read -rp "Press ENTER to continue..."; }

configure_kubectl() {
  echo "Configuring kubectl..."
  aws eks update-kubeconfig --region "$REGION" --name "$CLUSTER_NAME"
  kubectl get nodes -o wide
}

get_node_sg() {
  local node="$1"
  local instance_id
  instance_id=$(aws ec2 describe-instances \
    --filters "Name=private-dns-name,Values=$node" \
    --query "Reservations[0].Instances[0].InstanceId" \
    --output text \
    --region "$REGION")

  aws ec2 describe-instances \
    --instance-ids "$instance_id" \
    --query "Reservations[0].Instances[0].SecurityGroups[0].GroupId" \
    --output text \
    --region "$REGION"
}

open_port() {
  local sg="$1"
  local port="$2"
  aws ec2 authorize-security-group-ingress \
    --group-id "$sg" \
    --protocol tcp \
    --port "$port" \
    --cidr 0.0.0.0/0 \
    --region "$REGION" 2>/dev/null || true
}

close_port() {
  local sg="$1"
  local port="$2"
  aws ec2 revoke-security-group-ingress \
    --group-id "$sg" \
    --protocol tcp \
    --port "$port" \
    --cidr 0.0.0.0/0 \
    --region "$REGION" 2>/dev/null || true
}

### =========================
### POD MANAGEMENT
### =========================
deploy_app() {
  local name="$1"
  shift
  local port="$1"
  local image="$2"
  local workdir="${3:-}"
  shift 3 || true
  local cmd="$*"

  kubectl delete pod "$name" --ignore-not-found

  cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: $name
  labels:
    app: $name
spec:
  containers:
  - name: $name
    image: $image
    ${workdir:+workingDir: $workdir}
    ${cmd:+command: ["/bin/sh","-c"]}
    ${cmd:+args: ["$cmd"]}
    ports:
    - containerPort: $port
      hostPort: $port
EOF

  echo "Waiting for pod to schedule..."
  kubectl wait --for=condition=Ready pod/$name --timeout=120s

  local node
  node=$(kubectl get pod "$name" -o jsonpath='{.spec.nodeName}')
  local sg
  sg=$(get_node_sg "$node")
  open_port "$sg" "$port"

  echo "Pod deployed on node: $node"
}

destroy_app() {
  local name="$1"
  local port="$2"

  local node
  node=$(kubectl get pod "$name" -o jsonpath='{.spec.nodeName}' 2>/dev/null || true)
  if [[ -n "$node" ]]; then
    local sg
    sg=$(get_node_sg "$node")
    close_port "$sg" "$port"
  fi

  kubectl delete pod "$name" --ignore-not-found
  echo "Pod $name removed"
}

discover_apps() {
  echo ""
  echo "Application discovery"
  echo "----------------------------"

  for app in "${!APPS[@]}"; do
    if ! kubectl get pod "$app" &>/dev/null; then
      echo "$app → not running"
      continue
    fi

    local node instance_id public_ip port
    node=$(kubectl get pod "$app" -o jsonpath='{.spec.nodeName}')
    instance_id=$(aws ec2 describe-instances \
      --filters "Name=private-dns-name,Values=$node" \
      --query "Reservations[0].Instances[0].InstanceId" \
      --output text \
      --region "$REGION")
    public_ip=$(aws ec2 describe-instances \
      --instance-ids "$instance_id" \
      --query "Reservations[0].Instances[0].PublicIpAddress" \
      --output text \
      --region "$REGION")
    port=$(echo "${APPS[$app]}" | awk '{print $1}')

    echo "$app → http://${public_ip}:${port} (node: $node)"
  done
}

app_menu() {
  local app="$1"
  read -r port image workdir cmd <<< "${APPS[$app]}"

  while true; do
    clear
    echo "App: $app"
    echo "1) Create pod"
    echo "2) Destroy pod"
    echo "0) Back"
    read -rp "Choice: " c
    case "$c" in
      1) deploy_app "$app" "$port" "$image" "$workdir" "$cmd"; pause ;;
      2) destroy_app "$app" "$port"; pause ;;
      0) break ;;
    esac
  done
}

### =========================
### MAIN MENU
### =========================
while true; do
  clear
  echo "=== EKS CloudShell Lab Control ==="
  echo "1) Configure kubectl & verify cluster"
  echo "2) v1fs-icap-server"
  echo "3) trendai"
  echo "4) malware-samples"
  echo "5) Application discovery (node + URL)"
  echo "0) Exit"
  read -rp "Select option: " opt

  case "$opt" in
    1) configure_kubectl; pause ;;
    2) app_menu v1fs-icap ;;
    3) app_menu trendai ;;
    4) app_menu malware-samples ;;
    5) discover_apps; pause ;;
    0) exit 0 ;;
  esac
done
