envsubst < Chart.tpl.yaml > Chart.yaml
envsubst < values.tpl.yaml > values.yaml

helm template "$PROJECT_NAME" "." --show-only "templates/services/nginx-service.yaml" > release/services/nginx-service.yaml
helm template "$PROJECT_NAME" "." --show-only "templates/deployments/nginx-deployment.yaml" > release/deployments/nginx-deployment.yaml
helm template "$PROJECT_NAME" "." --show-only "templates/persistentvolumeclaims/nginx-persistentvolumeclaim.yaml" > release/persistentvolumeclaims/nginx-persistentvolumeclaim.yaml
helm template "$PROJECT_NAME" "." --show-only "templates/persistentvolumeclaims/nginx-ssl-persistentvolumeclaim.yaml" > release/persistentvolumeclaims/nginx-ssl-persistentvolumeclaim.yaml
helm template "$PROJECT_NAME" "." --show-only "templates/deployments/nginx-deployment.yaml" > release/deployments/nginx-deployment.yaml
helm template "$PROJECT_NAME" "." --show-only "templates/daemonsets/nvidia-device-plugin-daemonset.yaml" > release/daemonsets/nvidia-device-plugin-daemonset.yaml
helm template "$PROJECT_NAME" "." --show-only "templates/adminusers/dashboard-adminuser.yaml" > release/adminusers/dashboard-adminuser.yaml
helm template "$PROJECT_NAME" "." --show-only "templates/clusterroles/dashboard-clusterrole.yaml" > release/clusterroles/dashboard-clusterrole.yaml
helm template "$PROJECT_NAME" "." --show-only "templates/secrets/dashboard-secret.yaml" > release/secrets/dashboard-secret.yaml

IFS=' ' read -ra STACK_ARRAY <<< "$STACKS"
# Deploy services based on STACKS
for stack in "${STACK_ARRAY[@]}"; do
    adminusers_paths=$(find ./templates/adminusers -type f -name "${stack}-*")
    for path in $adminusers_paths; do
        filename=$(basename "$path")
        helm template "$PROJECT_NAME" "." --show-only "templates/adminusers/$filename" > release/adminusers/$filename
    done

    clusterroles_paths=$(find ./templates/clusterroles -type f -name "${stack}-*")
    for path in $clusterroles_paths; do
        filename=$(basename "$path")
        helm template "$PROJECT_NAME" "." --show-only "templates/clusterroles/$filename" > release/clusterroles/$filename
    done

    daemonsets_paths=$(find ./templates/daemonsets -type f -name "${stack}-*")
    for path in $daemonsets_paths; do
        filename=$(basename "$path")
        helm template "$PROJECT_NAME" "." --show-only "templates/daemonsets/$filename" > release/daemonsets/$filename
    done

    deployments_paths=$(find ./templates/deployments -type f -name "${stack}-*")
    for path in $deployments_paths; do
        filename=$(basename "$path")
        helm template "$PROJECT_NAME" "." --show-only "templates/deployments/$filename" > release/deployments/$filename
    done

    networkpolicies_paths=$(find ./templates/networkpolicies -type f -name "${stack}-*")
    for path in $networkpolicies_paths; do
        filename=$(basename "$path")
        helm template "$PROJECT_NAME" "." --show-only "templates/networkpolicies/$filename" > release/networkpolicies/$filename
    done

    persistentvolumeclaims_paths=$(find ./templates/persistentvolumeclaims -type f -name "${stack}-*")
    for path in $persistentvolumeclaims_paths; do
        filename=$(basename "$path")
        helm template "$PROJECT_NAME" "." --show-only "templates/persistentvolumeclaims/$filename" > release/persistentvolumeclaims/$filename
    done

    runtimeclasses_paths=$(find ./templates/runtimeclasses -type f -name "${stack}-*")
    for path in $runtimeclasses_paths; do
        filename=$(basename "$path")
        helm template "$PROJECT_NAME" "." --show-only "templates/runtimeclasses/$filename" > release/runtimeclasses/$filename
    done

    secrets_paths=$(find ./templates/secrets -type f -name "${stack}-*")
    for path in $secrets_paths; do
        filename=$(basename "$path")
        helm template "$PROJECT_NAME" "." --show-only "templates/secrets/$filename" > release/secrets/$filename
    done

    services_paths=$(find ./templates/services -type f -name "${stack}-*")
    for path in $services_paths; do
        filename=$(basename "$path")
        helm template "$PROJECT_NAME" "." --show-only "templates/services/$filename" > release/services/$filename
    done
done