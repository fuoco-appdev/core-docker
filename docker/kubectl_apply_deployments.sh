source ./kubectl_setup_args.sh

if [ -n "$ENV_FILE" ]; then
    echo "Skipping env deployments setup"
else
    ENV_FILE=".env"
    source ./kubectl_setup_env.sh
fi

if [ ! -d "./kubernetes/release/deployments" ]; then
    mkdir -p "./kubernetes/release/deployments"
    echo "Directory ./kubernetes/release/deployments created."
else 
    echo "Directory ./kubernetes/release/deployments already exists."
fi

kubectl --kubeconfig="$KUBECONFIG_PATH" apply -f kubernetes/release/deployments/nginx-deployment.yaml

IFS=' ' read -ra STACK_ARRAY <<< "$STACKS"
for stack in "${STACK_ARRAY[@]}"; do
    deployments_paths=$(find ./kubernetes/templates/deployments -type f -name "${stack}-*")
    for path in $deployments_paths; do
        filename=$(basename "$path")
        envsubst < kubernetes/release/deployments/$filename | kubectl --kubeconfig="$KUBECONFIG_PATH" apply -f - 
    done
done