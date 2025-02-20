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

if [ ! -d "./release/clusterroles" ]; then
    mkdir -p "./release/clusterroles"
    echo "Directory ./release/clusterroles created."
else 
    echo "Directory ./release/clusterroles already exists."
fi

if [ ! -d "./release/daemonsets" ]; then
    mkdir -p "./release/daemonsets"
    echo "Directory ./release/daemonsets created."
else 
    echo "Directory ./release/daemonsets already exists."
fi

if [ ! -d "./release/deployments" ]; then
    mkdir -p "./release/deployments"
    echo "Directory ./release/deployments created."
else 
    echo "Directory ./release/deployments already exists."
fi

if [ ! -d "./release/networkpolicies" ]; then
    mkdir -p "./release/networkpolicies"
    echo "Directory ./release/networkpolicies created."
else 
    echo "Directory ./release/networkpolicies already exists."
fi

if [ ! -d "./release/persistentvolumeclaims" ]; then
    mkdir -p "./release/persistentvolumeclaims"
    echo "Directory ./release/persistentvolumeclaims created."
else 
    echo "Directory ./release/persistentvolumeclaims already exists."
fi

if [ ! -d "./release/runtimeclasses" ]; then
    mkdir -p "./release/runtimeclasses"
    echo "Directory ./release/runtimeclasses created."
else 
    echo "Directory ./release/runtimeclasses already exists."
fi

if [ ! -d "./release/secrets" ]; then
    mkdir -p "./release/secrets"
    echo "Directory ./release/secrets created."
else 
    echo "Directory ./release/secrets already exists."
fi

if [ ! -d "./release/services" ]; then
    mkdir -p "./release/services"
    echo "Directory ./release/services created."
else 
    echo "Directory ./release/services already exists."
fi

source ./setup_password.sh
source ./setup_ssl.sh

IFS=' ' read -ra STACK_ARRAY <<< "$STACKS"

# Check if the directory exists, if not, create it
source ./setup_templates.sh
source ./apply_adminusers.sh
source ./apply_clusterroles.sh
source ./apply_daemonsets.sh
source ./apply_deployments.sh
source ./apply_networkpolicies.sh
source ./apply_persistentvolumeclaims.sh
source ./apply_runtimeclasses.sh
source ./apply_secrets.sh
source ./apply_services.sh

source ./setup_nginx.sh
source ./setup_core.sh
source ./setup_ai.sh

kubectl --kubeconfig="$KUBECONFIG_PATH" apply -f "https://raw.githubusercontent.com/kubernetes/dashboard/v2.7.0/aio/deploy/recommended.yaml"
kubectl --kubeconfig="$KUBECONFIG_PATH" proxy &

echo 'Dashboard token:'
kubectl --kubeconfig="$KUBECONFIG_PATH" get secret admin-user -n kubernetes-dashboard -o jsonpath={".data.token"} | base64 -d

exit 0