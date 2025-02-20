source ./setup_args.sh

if [ -n "$ENV_FILE" ]; then
    echo "Skipping env setup"
else
    ENV_FILE="../.env"
    source ./setup_env.sh
fi

if [ ! -d "./release/persistentvolumeclaims" ]; then
    mkdir -p "./release/persistentvolumeclaims"
    echo "Directory ./release/persistentvolumeclaims created."
else 
    echo "Directory ./release/persistentvolumeclaims already exists."
fi

kubectl --kubeconfig="$KUBECONFIG_PATH" apply -f release/persistentvolumeclaims/nginx-persistentvolumeclaim.yaml
kubectl --kubeconfig="$KUBECONFIG_PATH" apply -f release/persistentvolumeclaims/nginx-ssl-persistentvolumeclaim.yaml

IFS=' ' read -ra STACK_ARRAY <<< "$STACKS"
for stack in "${STACK_ARRAY[@]}"; do
    persistentvolumeclaims_paths=$(find ./templates/persistentvolumeclaims -type f -name "${stack}-*")
    for path in $persistentvolumeclaims_paths; do
        filename=$(basename "$path")
        envsubst < release/persistentvolumeclaims/$filename | kubectl --kubeconfig="$KUBECONFIG_PATH" apply -f - 
    done
done