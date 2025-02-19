env_file="../.env"

# Check if the .env file exists
if [ -f "$env_file" ]; then
    # Source the .env file
    . "$env_file"
else
    echo "Error: .env file not found at $env_file"
    exit 1
fi

# Check if an argument (config file path) is provided
if [ -n "$1" ]; then
    KUBECONFIG_PATH="$1"
else
    KUBECONFIG_PATH=""
fi

export $(grep -v '^#' $env_file | cut -d= -f1)

helm template "$PROJECT_NAME" "." | kubectl delete -f -

kubectl --kubeconfig="$KUBECONFIG_PATH" delete deployments --all --all-namespaces
kubectl --kubeconfig="$KUBECONFIG_PATH" delete pods --all --all-namespaces
kubectl --kubeconfig="$KUBECONFIG_PATH" delete services --all --all-namespaces
kubectl --kubeconfig="$KUBECONFIG_PATH" delete configmaps --all --all-namespaces
kubectl --kubeconfig="$KUBECONFIG_PATH" delete secrets --all --all-namespaces
kubectl --kubeconfig="$KUBECONFIG_PATH" delete replicasets --all --all-namespaces
kubectl --kubeconfig="$KUBECONFIG_PATH" delete statefulsets --all --all-namespaces
kubectl --kubeconfig="$KUBECONFIG_PATH" delete persistentvolumeclaims --all --all-namespaces
kubectl --kubeconfig="$KUBECONFIG_PATH" delete jobs --all --all-namespaces
kubectl --kubeconfig="$KUBECONFIG_PATH" delete cronjobs --all --all-namespaces
kubectl --kubeconfig="$KUBECONFIG_PATH" delete daemonsets --all --all-namespaces
kubectl --kubeconfig="$KUBECONFIG_PATH" delete ingress --all --all-namespaces
kubectl --kubeconfig="$KUBECONFIG_PATH" delete networkpolicies --all --all-namespaces