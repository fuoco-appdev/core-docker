source ./kubectl_setup_args.sh

if [ -n "$ENV_FILE" ]; then
    echo "Skipping env networkpolicies setup"
else
    ENV_FILE=".env"
    source ./kubectl_setup_env.sh
fi

if [ ! -d "./kubernetes/release/networkpolicies" ]; then
    mkdir -p "./kubernetes/release/networkpolicies"
    echo "Directory ./kubernetes/release/networkpolicies created."
else 
    echo "Directory ./kubernetes/release/networkpolicies already exists."
fi

IFS=' ' read -ra STACK_ARRAY <<< "$STACKS"
for stack in "${STACK_ARRAY[@]}"; do
    networkpolicies_paths=$(find ./kubernetes/templates/networkpolicies -type f -name "${stack}-*")
    for path in $networkpolicies_paths; do
        filename=$(basename "$path")
        envsubst < kubernetes/release/networkpolicies/$filename | kubectl --kubeconfig="$KUBECONFIG_PATH" apply -f - 
    done
done