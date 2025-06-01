if [ -n "$ENV_FILE" ]; then
    echo "Skipping env templates setup"
else
    ENV_FILE=".env"
    source ./kubectl_setup_env.sh
fi

envsubst < Chart.tpl.yaml > Chart.yaml
envsubst < values.tpl.yaml > values.yaml

helm template "$PROJECT_NAME" "." --show-only "kubernetes/templates/services/nginx-service.yaml" > kubernetes/release/services/nginx-service.yaml
helm template "$PROJECT_NAME" "." --show-only "kubernetes/templates/deployments/nginx-deployment.yaml" > kubernetes/release/deployments/nginx-deployment.yaml
helm template "$PROJECT_NAME" "." --show-only "kubernetes/templates/persistentvolumeclaims/nginx-persistentvolumeclaim.yaml" > kubernetes/release/persistentvolumeclaims/nginx-persistentvolumeclaim.yaml
helm template "$PROJECT_NAME" "." --show-only "kubernetes/templates/persistentvolumeclaims/nginx-ssl-persistentvolumeclaim.yaml" > kubernetes/release/persistentvolumeclaims/nginx-ssl-persistentvolumeclaim.yaml
helm template "$PROJECT_NAME" "." --show-only "kubernetes/templates/deployments/nginx-deployment.yaml" > kubernetes/release/deployments/nginx-deployment.yaml
helm template "$PROJECT_NAME" "." --show-only "kubernetes/templates/daemonsets/nvidia-device-plugin-daemonset.yaml" > kubernetes/release/daemonsets/nvidia-device-plugin-daemonset.yaml
helm template "$PROJECT_NAME" "." --show-only "kubernetes/templates/adminusers/dashboard-adminuser.yaml" > kubernetes/release/adminusers/dashboard-adminuser.yaml
helm template "$PROJECT_NAME" "." --show-only "kubernetes/templates/clusterroles/dashboard-clusterrole.yaml" > kubernetes/release/clusterroles/dashboard-clusterrole.yaml
helm template "$PROJECT_NAME" "." --show-only "kubernetes/templates/secrets/dashboard-secret.yaml" > kubernetes/release/secrets/dashboard-secret.yaml

IFS=' ' read -ra STACK_ARRAY <<< "$STACKS"
# Deploy services based on STACKS
for stack in "${STACK_ARRAY[@]}"; do
    adminusers_paths=$(find ./kubernetes/templates/adminusers -type f -name "${stack}-*")
    for path in $adminusers_paths; do
        filename=$(basename "$path")
        helm template "$PROJECT_NAME" "." --show-only "kubernetes/templates/adminusers/$filename" > kubernetes/release/adminusers/$filename
    done

    clusterroles_paths=$(find ./kubernetes/templates/clusterroles -type f -name "${stack}-*")
    for path in $clusterroles_paths; do
        filename=$(basename "$path")
        helm template "$PROJECT_NAME" "." --show-only "kubernetes/templates/clusterroles/$filename" > kubernetes/release/clusterroles/$filename
    done

    daemonsets_paths=$(find ./kubernetes/templates/daemonsets -type f -name "${stack}-*")
    for path in $daemonsets_paths; do
        filename=$(basename "$path")
        helm template "$PROJECT_NAME" "." --show-only "kubernetes/templates/daemonsets/$filename" > kubernetes/release/daemonsets/$filename
    done

    deployments_paths=$(find ./kubernetes/templates/deployments -type f -name "${stack}-*")
    for path in $deployments_paths; do
        filename=$(basename "$path")
        helm template "$PROJECT_NAME" "." --show-only "kubernetes/templates/deployments/$filename" > kubernetes/release/deployments/$filename
    done

    networkpolicies_paths=$(find ./kubernetes/templates/networkpolicies -type f -name "${stack}-*")
    for path in $networkpolicies_paths; do
        filename=$(basename "$path")
        helm template "$PROJECT_NAME" "." --show-only "kubernetes/templates/networkpolicies/$filename" > kubernetes/release/networkpolicies/$filename
    done

    persistentvolumeclaims_paths=$(find ./kubernetes/templates/persistentvolumeclaims -type f -name "${stack}-*")
    for path in $persistentvolumeclaims_paths; do
        filename=$(basename "$path")
        helm template "$PROJECT_NAME" "." --show-only "kubernetes/templates/persistentvolumeclaims/$filename" > kubernetes/release/persistentvolumeclaims/$filename
    done

    runtimeclasses_paths=$(find ./kubernetes/templates/runtimeclasses -type f -name "${stack}-*")
    for path in $runtimeclasses_paths; do
        filename=$(basename "$path")
        helm template "$PROJECT_NAME" "." --show-only "kubernetes/templates/runtimeclasses/$filename" > kubernetes/release/runtimeclasses/$filename
    done

    secrets_paths=$(find ./kubernetes/templates/secrets -type f -name "${stack}-*")
    for path in $secrets_paths; do
        filename=$(basename "$path")
        helm template "$PROJECT_NAME" "." --show-only "kubernetes/templates/secrets/$filename" > kubernetes/release/secrets/$filename
    done

    services_paths=$(find ./kubernetes/templates/services -type f -name "${stack}-*")
    for path in $services_paths; do
        filename=$(basename "$path")
        helm template "$PROJECT_NAME" "." --show-only "kubernetes/templates/services/$filename" > kubernetes/release/services/$filename
    done
done