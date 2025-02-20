source ./setup_args.sh

if [ -n "$ENV_FILE" ]; then
    echo "Skipping env setup"
else
    ENV_FILE="../.env"
    source ./setup_env.sh
fi

if [ ! -d "./release/networkpolicies" ]; then
    mkdir -p "./release/networkpolicies"
    echo "Directory ./release/networkpolicies created."
else 
    echo "Directory ./release/networkpolicies already exists."
fi

IFS=' ' read -ra STACK_ARRAY <<< "$STACKS"
for stack in "${STACK_ARRAY[@]}"; do
    networkpolicies_paths=$(find ./templates/networkpolicies -type f -name "${stack}-*")
    for path in $networkpolicies_paths; do
        filename=$(basename "$path")
        envsubst < release/networkpolicies/$filename | kubectl --kubeconfig="$KUBECONFIG_PATH" apply -f - 
    done
done