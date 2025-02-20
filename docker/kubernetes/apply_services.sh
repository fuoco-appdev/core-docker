source ./setup_args.sh

if [ -n "$ENV_FILE" ]; then
    echo "Skipping env setup"
else
    ENV_FILE="../.env"
    source ./setup_env.sh
fi

if [ ! -d "./release/services" ]; then
    mkdir -p "./release/services"
    echo "Directory ./release/services created."
else 
    echo "Directory ./release/services already exists."
fi

kubectl --kubeconfig="$KUBECONFIG_PATH" apply -f release/services/nginx-service.yaml

IFS=' ' read -ra STACK_ARRAY <<< "$STACKS"
for stack in "${STACK_ARRAY[@]}"; do
    services_paths=$(find ./templates/services -type f -name "${stack}-*")
    for path in $services_paths; do
        filename=$(basename "$path")
        envsubst < release/services/$filename | kubectl --kubeconfig="$KUBECONFIG_PATH" apply -f - 
    done
done