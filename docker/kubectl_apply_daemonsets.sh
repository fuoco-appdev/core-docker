source ./kubectl_setup_args.sh

if [ -n "$ENV_FILE" ]; then
    echo "Skipping env deamonsets setup"
else
    ENV_FILE=".env"
    source ./kubectl_setup_env.sh
fi

if [ ! -d "./kubernetes/release/daemonsets" ]; then
    mkdir -p "./kubernetes/release/daemonsets"
    echo "Directory ./kubernetes/release/daemonsets created."
else 
    echo "Directory ./kubernetes/release/daemonsets already exists."
fi

if [[ "${STACK_ARRAY[@]}" =~ "ai" ]]; then
    kubectl --kubeconfig="$KUBECONFIG_PATH" apply -f kubernetes/release/daemonsets/nvidia-device-plugin-daemonset.yaml
else
    echo "Skipping nvidia-device-plugin-daemonset.yaml deployment"
fi

IFS=' ' read -ra STACK_ARRAY <<< "$STACKS"
for stack in "${STACK_ARRAY[@]}"; do
    daemonsets_paths=$(find ./kubernetes/templates/daemonsets -type f -name "${stack}-*")
    for path in $daemonsets_paths; do
        filename=$(basename "$path")
        envsubst < kubernetes/release/daemonsets/$filename | kubectl --kubeconfig="$KUBECONFIG_PATH" apply -f - 
    done
done