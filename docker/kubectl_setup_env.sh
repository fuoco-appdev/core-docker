if [ -n "$ENV_FILE" ]; then
    echo "Skipping env setup"
else
    ENV_FILE="../.env"
    source ./load_env.sh
fi

kubectl --kubeconfig="$KUBECONFIG_PATH" delete secret env-secrets --ignore-not-found
kubectl --kubeconfig="$KUBECONFIG_PATH" create secret generic env-secrets --from-env-file=../.env