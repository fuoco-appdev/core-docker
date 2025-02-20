source ./setup_args.sh

if [ -n "$ENV_FILE" ]; then
    echo "Skipping env setup"
else
    ENV_FILE="../.env"
    source ./setup_env.sh
fi

if [ ! -d "./release/daemonsets" ]; then
    mkdir -p "./release/daemonsets"
    echo "Directory ./release/daemonsets created."
else 
    echo "Directory ./release/daemonsets already exists."
fi

if [[ "${STACK_ARRAY[@]}" =~ "ai" ]]; then
    kubectl --kubeconfig="$KUBECONFIG_PATH" apply -f release/daemonsets/nvidia-device-plugin-daemonset.yaml
else
    echo "Skipping nvidia-device-plugin-daemonset.yaml deployment"
fi

IFS=' ' read -ra STACK_ARRAY <<< "$STACKS"
for stack in "${STACK_ARRAY[@]}"; do
    daemonsets_paths=$(find ./templates/daemonsets -type f -name "${stack}-*")
    for path in $daemonsets_paths; do
        filename=$(basename "$path")
        envsubst < release/daemonsets/$filename | kubectl --kubeconfig="$KUBECONFIG_PATH" apply -f - 
    done
done