source ./setup_args.sh

if [ -n "$ENV_FILE" ]; then
    echo "Skipping env setup"
else
    ENV_FILE="../.env"
    source ./setup_env.sh
fi

if [ ! -d "./release/runtimeclasses" ]; then
    mkdir -p "./release/runtimeclasses"
    echo "Directory ./release/runtimeclasses created."
else 
    echo "Directory ./release/runtimeclasses already exists."
fi

IFS=' ' read -ra STACK_ARRAY <<< "$STACKS"
for stack in "${STACK_ARRAY[@]}"; do
    runtimeclasses_paths=$(find ./templates/runtimeclasses -type f -name "${stack}-*")
    for path in $runtimeclasses_paths; do
        filename=$(basename "$path")
        envsubst < release/runtimeclasses/$filename | kubectl --kubeconfig="$KUBECONFIG_PATH" apply -f - 
    done
done