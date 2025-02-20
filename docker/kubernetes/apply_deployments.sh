source ./setup_args.sh

if [ -n "$ENV_FILE" ]; then
    echo "Skipping env setup"
else
    ENV_FILE="../.env"
    source ./setup_env.sh
fi

if [ ! -d "./release/deployments" ]; then
    mkdir -p "./release/deployments"
    echo "Directory ./release/deployments created."
else 
    echo "Directory ./release/deployments already exists."
fi

kubectl --kubeconfig="$KUBECONFIG_PATH" apply -f release/deployments/nginx-deployment.yaml

IFS=' ' read -ra STACK_ARRAY <<< "$STACKS"
for stack in "${STACK_ARRAY[@]}"; do
    deployments_paths=$(find ./templates/deployments -type f -name "${stack}-*")
    for path in $deployments_paths; do
        filename=$(basename "$path")
        envsubst < release/deployments/$filename | kubectl --kubeconfig="$KUBECONFIG_PATH" apply -f - 
    done
done