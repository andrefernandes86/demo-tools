#!/usr/bin/env bash
set -euo pipefail

### =================================================
### CONFIGURATION
### =================================================
CLUSTER_NAME="eks-lab"
REGION="us-east-1"
ACCOUNT_ID="195216432632"
ECR="${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com"

declare -A APPS
APPS[v1fs-demo]="8080 ${ECR}/demo-v1fs-icap /icap-scan-web python3 app.py"
APPS[v1aisec-demo]="8000 ${ECR}/tools-ai-sec-demo"
APPS[malware-samples]="80 ${ECR}/tools-malware-samples"

### =================================================
### UTILS
### =================================================
pause() { read -rp "Press ENTER to continue..."; }

configure_kubectl() {
  echo "Configuring kubectl for EKS cluster..."
  aws eks update-kubeconfig --region "$REGION" --name "$CLUSTER_NAME"
  kubectl get nodes -o wide
}

get_instance_id_from_node() {
  aws ec2 describe-instances \
    --filters "Name=private-dns-name,Values=$1" \
    --query "Reservations[0].Instances[0].InstanceId" \
    --output text \
    --region "$REGION"
}

get_node_sg() {
  aws ec2 describe-instances \
    --instance-ids "$1" \
    --query "Reservations[0].Instances[0].SecurityGroups[0].GroupId" \
    --output text \
    --region "$REGION"
}

open_port() {
  aws ec2 authorize-security-group-ingress \
    --group-id "$1" \
    --protocol tcp \
    --port "$2" \
    --cidr 0.0.0.0/0 \
    --region "$REGION" 2>/dev/null || true
}

close_port() {
  aws ec2 revoke-security-group-ingress \
    --group-id "$1" \
    --protocol tcp \
    --port "$2" \
    --cidr 0.0.0.0/0 \
    --region "$REGION" 2>/dev/null || true
}

### =================================================
### POD MANAGEMENT
### =================================================
deploy_app() {
  local name="$1" port="$2" image="$3" workdir="${4:-}" cmd="${5:-}"

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

  echo "Waiting for pod to be ready..."
  kubectl wait --for=condition=Ready pod/$name --timeout=120s

  node=$(kubectl get pod "$name" -o jsonpath='{.spec.nodeName}')
  instance_id=$(get_instance_id_from_node "$node")
  sg=$(get_node_sg "$instance_id")

  open_port "$sg" "$port"

  echo "✔ $name running on node $node"
}

destroy_app() {
  local name="$1" port="$2"

  if kubectl get pod "$name" &>/dev/null; then
    node=$(kubectl get pod "$name" -o jsonpath='{.spec.nodeName}')
    instance_id=$(get_instance_id_from_node "$node")
    sg=$(get_node_sg "$instance_id")
    close_port "$sg" "$port"
  fi

  kubectl delete pod "$name" --ignore-not-found
  echo "✔ $name removed"
}

discover_apps() {
  echo ""
  echo "Application discovery"
  echo "-----------------------------"

  for app in "${!APPS[@]}"; do
    if ! kubectl get pod "$app" &>/dev/null; then
      echo "$app → not running"
      continue
    fi

    node=$(kubectl get pod "$app" -o jsonpath='{.spec.nodeName}')
    instance_id=$(get_instance_id_from_node "$node")
    public_ip=$(aws ec2 describe-instances \
      --instance-ids "$instance_id" \
      --query "Reservations[0].Instances[0].PublicIpAddress" \
      --output text \
      --region "$REGION")

    port=$(echo "${APPS[$app]}" | awk '{print $1}')
    echo "$app → http://${public_ip}:${port} (node: $node)"
  done
}

### =================================================
### SECURITY GROUP MANAGEMENT
### =================================================
manage_security_groups() {
  echo ""
  echo "Collecting worker node Security Groups..."

  mapfile -t SGS < <(
    kubectl get nodes -o jsonpath='{.items[*].spec.providerID}' |
    tr ' ' '\n' |
    sed 's|.*/||' |
    while read -r id; do
      aws ec2 describe-instances \
        --instance-ids "$id" \
        --query 'Reservations[0].Instances[0].SecurityGroups[*].GroupId' \
        --output text \
        --region "$REGION"
    done | tr '\t' '\n' | sort -u
  )

  for sg in "${SGS[@]}"; do
    echo ""
    echo "Security Group: $sg"
    aws ec2 describe-security-groups \
      --group-ids "$sg" \
      --query 'SecurityGroups[0].IpPermissions[*].{Port:FromPort,IPs:IpRanges[*].CidrIp}' \
      --output table \
      --region "$REGION"
  done

  echo ""
  read -rp "Do you want to add a new allowed IP? (yes/no): " answer
  [[ "$answer" != "yes" ]] && return

  read -rp "Enter IP or CIDR (example: 203.0.113.10/32): " cidr
  read -rp "Enter TCP port: " port

  for sg in "${SGS[@]}"; do
    aws ec2 authorize-security-group-ingress \
      --group-id "$sg" \
      --protocol tcp \
      --port "$port" \
      --cidr "$cidr" \
      --region "$REGION" 2>/dev/null || true
  done

  echo ""
  echo "Final Security Group rules:"
  for sg in "${SGS[@]}"; do
    echo ""
    echo "Security Group: $sg"
    aws ec2 describe-security-groups \
      --group-ids "$sg" \
      --query 'SecurityGroups[0].IpPermissions[*].{Port:FromPort,IPs:IpRanges[*].CidrIp}' \
      --output table \
      --region "$REGION"
  done
}

### =================================================
### APP MENU
### =================================================
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

### =================================================
### MAIN MENU
### =================================================
while true; do
  clear
  echo "=== EKS CloudShell Lab Control ==="
  echo "1) Configure kubectl & verify cluster"
  echo "2) v1fs-demo"
  echo "3) v1aisec-demo"
  echo "4) malware-samples"
  echo "5) Application discovery (node + URL)"
  echo "6) Manage Security Group allowed IPs"
  echo "0) Exit"
  read -rp "Select option: " opt

  case "$opt" in
    1) configure_kubectl; pause ;;
    2) app_menu v1fs-demo ;;
    3) app_menu v1aisec-demo ;;
    4) app_menu malware-samples ;;
    5) discover_apps; pause ;;
    6) manage_security_groups; pause ;;
    0) exit 0 ;;
  esac
done
