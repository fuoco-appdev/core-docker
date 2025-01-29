env_file="../.env"

# Check if the .env file exists
if [ -f "$env_file" ]; then
    # Source the .env file
    . "$env_file"
else
    echo "Error: .env file not found at $env_file"
    exit 1
fi

export $(grep -v '^#' $env_file | cut -d= -f1)

helm template "$PROJECT_NAME" "." | kubectl delete -f -

kubectl delete deployments --all --all-namespaces
kubectl delete pods --all --all-namespaces
kubectl delete services --all --all-namespaces
kubectl delete configmaps --all --all-namespaces
kubectl delete secrets --all --all-namespaces
kubectl delete replicasets --all --all-namespaces
kubectl delete statefulsets --all --all-namespaces
# kubectl delete persistentvolumeclaims --all --all-namespaces
kubectl delete jobs --all --all-namespaces
kubectl delete cronjobs --all --all-namespaces
kubectl delete daemonsets --all --all-namespaces
kubectl delete ingress --all --all-namespaces
kubectl delete networkpolicies --all --all-namespaces