source ./kubectl_setup_args.sh

if [ -n "$ENV_FILE" ]; then
    echo "Skipping env runtimeclasses setup"
else
    ENV_FILE=".env"
    source ./kubectl_setup_env.sh
fi

if [ ! -d "./kubernetes/release/runtimeclasses" ]; then
    mkdir -p "./kubernetes/release/runtimeclasses"
    echo "Directory ./kubernetes/release/runtimeclasses created."
else 
    echo "Directory ./kubernetes/release/runtimeclasses already exists."
fi

IFS=' ' read -ra STACK_ARRAY <<< "$STACKS"
for stack in "${STACK_ARRAY[@]}"; do
    runtimeclasses_paths=$(find ./kubernetes/templates/runtimeclasses -type f -name "${stack}-*")
    for path in $runtimeclasses_paths; do
        filename=$(basename "$path")
        envsubst < kubernetes/release/runtimeclasses/$filename | kubectl --kubeconfig="$KUBECONFIG_PATH" apply -f - 
    done
done