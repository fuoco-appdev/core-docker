source ./setup_args.sh

if [ -n "$ENV_FILE" ]; then
    echo "Skipping env setup"
else
    ENV_FILE="../.env"
    source ./setup_env.sh
fi

if [ ! -d "./release/clusterroles" ]; then
    mkdir -p "./release/clusterroles"
    echo "Directory ./release/clusterroles created."
else 
    echo "Directory ./release/clusterroles already exists."
fi

kubectl --kubeconfig="$KUBECONFIG_PATH" apply -f release/dashboard-clusterrole.yaml -n kubernetes-dashboard

IFS=' ' read -ra STACK_ARRAY <<< "$STACKS"
for stack in "${STACK_ARRAY[@]}"; do
    clusterroles_paths=$(find ./templates/clusterroles -type f -name "${stack}-*")
    for path in $clusterroles_paths; do
        filename=$(basename "$path")
        envsubst < release/clusterroles/$filename | kubectl --kubeconfig="$KUBECONFIG_PATH" apply -f - 
    done
done