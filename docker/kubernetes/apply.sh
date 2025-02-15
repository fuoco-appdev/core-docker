IFS=' ' read -ra STACK_ARRAY <<< "$STACKS"

# Check if an argument (config file path) is provided
if [ -n "$1" ]; then
    KUBECONFIG_PATH="$1"
else
    KUBECONFIG_PATH=""
fi

source ./setup_env.sh
source ./setup_password.sh

# Check if the directory exists, if not, create it
if [ ! -d "./release" ]; then
    mkdir -p "./release"
    echo "Directory ./release created."
else 
    echo "Directory ./release already exists."
fi

envsubst < Chart.tpl.yaml > Chart.yaml
envsubst < values.tpl.yaml > values.yaml

helm template "$PROJECT_NAME" "." --show-only "templates/nginx-config-persistentvolumeclaim.yaml" > release/nginx-config-persistentvolumeclaim.yaml
kubectl --kubeconfig="$KUBECONFIG_PATH" apply -f release/nginx-config-persistentvolumeclaim.yaml

helm template "$PROJECT_NAME" "." --show-only "templates/nginx-service.yaml" > release/nginx-service.yaml
kubectl --kubeconfig="$KUBECONFIG_PATH" apply -f release/nginx-service.yaml

helm template "$PROJECT_NAME" "." --show-only "templates/nginx-deployment.yaml" > release/nginx-deployment.yaml
kubectl --kubeconfig="$KUBECONFIG_PATH" apply -f release/nginx-deployment.yaml

source ./setup_nginx.sh

if [[ "${STACK_ARRAY[@]}" =~ "ai" ]]; then
    helm  template "$PROJECT_NAME" "." --show-only "templates/nvidia-device-plugin-daemonset.yaml" > release/nvidia-device-plugin-daemonset.yaml
    kubectl --kubeconfig="$KUBECONFIG_PATH" apply -f release/nvidia-device-plugin-daemonset.yaml
else
    echo "Skipping nvidia-device-plugin-daemonset.yaml deployment"
fi

# Deploy services based on STACKS
for stack in "${STACK_ARRAY[@]}"; do
    stack_paths=$(find ./templates -type f -name "${stack}-*")
    for path in $stack_paths; do
        filename=$(basename "$path")
        helm template "$PROJECT_NAME" "." --show-only "templates/$filename" > release/$filename
        envsubst < release/$filename | kubectl --kubeconfig="$KUBECONFIG_PATH" apply -f - 
    done
done

source ./setup_core.sh
source ./setup_ai.sh

kubectl --kubeconfig="$KUBECONFIG_PATH" apply -f "https://raw.githubusercontent.com/kubernetes/dashboard/v2.7.0/aio/deploy/recommended.yaml"
kubectl --kubeconfig="$KUBECONFIG_PATH" proxy &

helm template "$PROJECT_NAME" "."  --show-only "templates/dashboard-adminuser.yaml" > release/dashboard-adminuser.yaml
kubectl --kubeconfig="$KUBECONFIG_PATH" apply -f release/dashboard-adminuser.yaml -n kubernetes-dashboard

helm template "$PROJECT_NAME" "." --show-only "templates/dashboard-clusterrole.yaml" > release/dashboard-clusterrole.yaml
kubectl --kubeconfig="$KUBECONFIG_PATH" apply -f release/dashboard-clusterrole.yaml -n kubernetes-dashboard

helm template "$PROJECT_NAME" "." --show-only "templates/dashboard-secret.yaml" > release/dashboard-secret.yaml
kubectl --kubeconfig="$KUBECONFIG_PATH" apply -f release/dashboard-secret.yaml -n kubernetes-dashboard

echo 'Dashboard token:'
kubectl --kubeconfig="$KUBECONFIG_PATH" get secret admin-user -n kubernetes-dashboard -o jsonpath={".data.token"} | base64 -d

exit 0