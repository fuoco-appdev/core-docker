source ./setup_args.sh

if [ -n "$ENV_FILE" ]; then
    echo "Skipping env setup"
else
    ENV_FILE="../.env"
    source ./setup_env.sh
fi

if [ ! -d "./release/adminusers" ]; then
    mkdir -p "./release/adminusers"
    echo "Directory ./release/adminusers created."
else 
    echo "Directory ./release/adminusers already exists."
fi

kubectl --kubeconfig="$KUBECONFIG_PATH" apply -f release/dashboard-adminuser.yaml -n kubernetes-dashboard

IFS=' ' read -ra STACK_ARRAY <<< "$STACKS"
for stack in "${STACK_ARRAY[@]}"; do
    adminusers_paths=$(find ./templates/adminusers -type f -name "${stack}-*")
    for path in $adminusers_paths; do
        filename=$(basename "$path")
        envsubst < release/adminusers/$filename | kubectl --kubeconfig="$KUBECONFIG_PATH" apply -f - 
    done
done