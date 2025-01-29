env_file="../.env"

# Check if the .env file exists
if [ -f "$env_file" ]; then
    # Source the .env file
    . "$env_file"
else
    echo "Error: .env file not found at $env_file"
    exit 1
fi

export $(grep -v '^#' $env_file | cut -d= -f1)

OS=$(uname -s)

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check if curl is installed
if ! command_exists curl; then
    echo "Error: curl is not installed. Please install curl to proceed."
    exit 1
fi

SECONDS=0
TIMEOUT=300
while [ ! -e "envsubst.exe" ]; do
    if [ $SECONDS -ge $TIMEOUT ]; then
        echo "Timeout: File $FILE did not appear within $TIMEOUT seconds."
        exit 1
    fi
    sleep 1
done

kubectl delete secret env-secrets --ignore-not-found
kubectl create secret generic env-secrets --from-env-file=../.env

NGINX_DEPLOYMENT_NAME=$(kubectl get deployments --no-headers=true | grep "^nginx" | awk '{print $1}' | head -n 1)
kubectl rollout restart deployment $NGINX_DEPLOYMENT_NAME -n default

IFS=' ' read -ra STACK_ARRAY <<< "$STACKS"

if [[ "${STACK_ARRAY[@]}" =~ "core" ]]; then
    ANALYTICS_DEPLOYMENT_NAME=$(kubectl get deployments --no-headers=true | grep "^analytics" | awk '{print $1}' | head -n 1)
    kubectl rollout restart deployment $ANALYTICS_DEPLOYMENT_NAME -n default
    AUTH_DEPLOYMENT_NAME=$(kubectl get deployments --no-headers=true | grep "^auth" | awk '{print $1}' | head -n 1)
    kubectl rollout restart deployment $AUTH_DEPLOYMENT_NAME -n default
    DB_DEPLOYMENT_NAME=$(kubectl get deployments --no-headers=true | grep "^db" | awk '{print $1}' | head -n 1)
    kubectl rollout restart deployment $DB_DEPLOYMENT_NAME -n default
    IMGPROXY_DEPLOYMENT_NAME=$(kubectl get deployments --no-headers=true | grep "^imgproxy" | awk '{print $1}' | head -n 1)
    kubectl rollout restart deployment $IMGPROXY_DEPLOYMENT_NAME -n default
    KONG_DEPLOYMENT_NAME=$(kubectl get deployments --no-headers=true | grep "^kong" | awk '{print $1}' | head -n 1)
    kubectl rollout restart deployment $KONG_DEPLOYMENT_NAME -n default
    META_DEPLOYMENT_NAME=$(kubectl get deployments --no-headers=true | grep "^meta" | awk '{print $1}' | head -n 1)
    kubectl rollout restart deployment $META_DEPLOYMENT_NAME -n default
    REALTIME_DEPLOYMENT_NAME=$(kubectl get deployments --no-headers=true | grep "^realtime" | awk '{print $1}' | head -n 1)
    kubectl rollout restart deployment $REALTIME_DEPLOYMENT_NAME -n default
    REST_DEPLOYMENT_NAME=$(kubectl get deployments --no-headers=true | grep "^rest" | awk '{print $1}' | head -n 1)
    kubectl rollout restart deployment $REST_DEPLOYMENT_NAME -n default
    STORAGE_DEPLOYMENT_NAME=$(kubectl get deployments --no-headers=true | grep "^storage" | awk '{print $1}' | head -n 1)
    kubectl rollout restart deployment $STORAGE_DEPLOYMENT_NAME -n default
    STUDIO_DEPLOYMENT_NAME=$(kubectl get deployments --no-headers=true | grep "^studio" | awk '{print $1}' | head -n 1)
    kubectl rollout restart deployment $STUDIO_DEPLOYMENT_NAME -n default
    SUPAVISOR_DEPLOYMENT_NAME=$(kubectl get deployments --no-headers=true | grep "^supavisor" | awk '{print $1}' | head -n 1)
    kubectl rollout restart deployment $SUPAVISOR_DEPLOYMENT_NAME -n default
    VECTOR_DEPLOYMENT_NAME=$(kubectl get deployments --no-headers=true | grep "^vector" | awk '{print $1}' | head -n 1)
    kubectl rollout restart deployment $VECTOR_DEPLOYMENT_NAME -n default
else
    echo "Skipping core stack"
fi

if [[ "${STACK_ARRAY[@]}" =~ "ecommerce" ]]; then
    MEDUSA_SERVER_DEPLOYMENT_NAME=$(kubectl get deployments --no-headers=true | grep "^medusa-server" | awk '{print $1}' | head -n 1)
    kubectl rollout restart deployment $MEDUSA_SERVER_DEPLOYMENT_NAME -n default
    MEILISEARCH_DEPLOYMENT_NAME=$(kubectl get deployments --no-headers=true | grep "^meilisearch" | awk '{print $1}' | head -n 1)
    kubectl rollout restart deployment $MEILISEARCH_DEPLOYMENT_NAME -n default
    REDIS_DEPLOYMENT_NAME=$(kubectl get deployments --no-headers=true | grep "^redis" | awk '{print $1}' | head -n 1)
    kubectl rollout restart deployment $REDIS_DEPLOYMENT_NAME -n default
else
    echo "Skipping core stack"
fi

if [[ "${STACK_ARRAY[@]}" =~ "s3" ]]; then
    MINIO_DEPLOYMENT_NAME=$(kubectl get deployments --no-headers=true | grep "^minio" | awk '{print $1}' | head -n 1)
    kubectl rollout restart deployment $MINIO_DEPLOYMENT_NAME -n default
else
    echo "Skipping core stack"
fi

if [[ "${STACK_ARRAY[@]}" =~ "ai" ]]; then
    ETCD_DEPLOYMENT_NAME=$(kubectl get deployments --no-headers=true | grep "^etcd" | awk '{print $1}' | head -n 1)
    kubectl rollout restart deployment $ETCD_DEPLOYMENT_NAME -n default
    OLLAMA_DEPLOYMENT_NAME=$(kubectl get deployments --no-headers=true | grep "^ollama" | awk '{print $1}' | head -n 1)
    kubectl rollout restart deployment $OLLAMA_DEPLOYMENT_NAME -n default
    OPEN_WEBUI_DEPLOYMENT_NAME=$(kubectl get deployments --no-headers=true | grep "^open-webui" | awk '{print $1}' | head -n 1)
    kubectl rollout restart deployment $OPEN_WEBUI_DEPLOYMENT_NAME -n default
    OPENEDAI_SPEECH_SERVER_DEPLOYMENT_NAME=$(kubectl get deployments --no-headers=true | grep "^openedai-speech-server" | awk '{print $1}' | head -n 1)
    kubectl rollout restart deployment $OPENEDAI_SPEECH_SERVER_DEPLOYMENT_NAME -n default
    STANDALONE_DEPLOYMENT_NAME=$(kubectl get deployments --no-headers=true | grep "^standalone" | awk '{print $1}' | head -n 1)
    kubectl rollout restart deployment $STANDALONE_DEPLOYMENT_NAME -n default
else
    echo "Skipping ai stack"
fi

DASHBOARD_DEPLOYMENT_NAME=$(kubectl get deployments --no-headers=true | grep "^dashboard" | awk '{print $1}' | head -n 1)
kubectl rollout restart deployment $DASHBOARD_DEPLOYMENT_NAME -n kubernetes-dashboard
kubectl proxy &

echo 'Dashboard token:'
kubectl get secret admin-user -n kubernetes-dashboard -o jsonpath={".data.token"} | base64 -d

exit 0