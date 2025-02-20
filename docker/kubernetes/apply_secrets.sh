source ./setup_args.sh

if [ -n "$ENV_FILE" ]; then
    echo "Skipping env setup"
else
    ENV_FILE="../.env"
    source ./setup_env.sh
fi

if [ ! -d "./release/secrets" ]; then
    mkdir -p "./release/secrets"
    echo "Directory ./release/secrets created."
else 
    echo "Directory ./release/secrets already exists."
fi

kubectl --kubeconfig="$KUBECONFIG_PATH" apply -f release/dashboard-secret.yaml -n kubernetes-dashboard

IFS=' ' read -ra STACK_ARRAY <<< "$STACKS"
for stack in "${STACK_ARRAY[@]}"; do
    secrets_paths=$(find ./templates/secrets -type f -name "${stack}-*")
    for path in $secrets_paths; do
        filename=$(basename "$path")
        envsubst < release/secrets/$filename | kubectl --kubeconfig="$KUBECONFIG_PATH" apply -f - 
    done
done