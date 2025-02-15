IFS=' ' read -ra STACK_ARRAY <<< "$STACKS"

# Check if an argument (config file path) is provided
if [ -n "$1" ]; then
    KUBECONFIG_PATH="$1"
else
    KUBECONFIG_PATH=""
fi

source ./setup_env.sh

NGINX_DEPLOYMENT_NAME=$(kubectl --kubeconfig="$KUBECONFIG_PATH" get deployments --no-headers=true | grep "^nginx" | awk '{print $1}' | head -n 1)
kubectl --kubeconfig="$KUBECONFIG_PATH" rollout restart deployment $NGINX_DEPLOYMENT_NAME

source ./setup_nginx.sh

if [[ "${STACK_ARRAY[@]}" =~ "core" ]]; then
    ANALYTICS_DEPLOYMENT_NAME=$(kubectl --kubeconfig="$KUBECONFIG_PATH" get deployments --no-headers=true | grep "^analytics.*Init" | awk '{print $1}' | head -n 1)
    kubectl --kubeconfig="$KUBECONFIG_PATH" rollout restart deployment $ANALYTICS_DEPLOYMENT_NAME -n default
    AUTH_DEPLOYMENT_NAME=$(kubectl --kubeconfig="$KUBECONFIG_PATH" get deployments --no-headers=true | grep "^auth.*Init" | awk '{print $1}' | head -n 1)
    kubectl --kubeconfig="$KUBECONFIG_PATH" rollout restart deployment $AUTH_DEPLOYMENT_NAME -n default
    DB_DEPLOYMENT_NAME=$(kubectl --kubeconfig="$KUBECONFIG_PATH" get deployments --no-headers=true | grep "^db.*Init" | awk '{print $1}' | head -n 1)
    kubectl --kubeconfig="$KUBECONFIG_PATH" rollout restart deployment $DB_DEPLOYMENT_NAME -n default
    IMGPROXY_DEPLOYMENT_NAME=$(kubectl --kubeconfig="$KUBECONFIG_PATH" get deployments --no-headers=true | grep "^imgproxy.*Init" | awk '{print $1}' | head -n 1)
    kubectl --kubeconfig="$KUBECONFIG_PATH" rollout restart deployment $IMGPROXY_DEPLOYMENT_NAME -n default
    KONG_DEPLOYMENT_NAME=$(kubectl --kubeconfig="$KUBECONFIG_PATH" get deployments --no-headers=true | grep "^kong.*Init" | awk '{print $1}' | head -n 1)
    kubectl --kubeconfig="$KUBECONFIG_PATH" rollout restart deployment $KONG_DEPLOYMENT_NAME -n default
    META_DEPLOYMENT_NAME=$(kubectl --kubeconfig="$KUBECONFIG_PATH" get deployments --no-headers=true | grep "^meta.*Init" | awk '{print $1}' | head -n 1)
    kubectl --kubeconfig="$KUBECONFIG_PATH" rollout restart deployment $META_DEPLOYMENT_NAME -n default
    REALTIME_DEPLOYMENT_NAME=$(kubectl get deployments --no-headers=true | grep "^realtime.*Init" | awk '{print $1}' | head -n 1)
    kubectl --kubeconfig="$KUBECONFIG_PATH" rollout restart deployment $REALTIME_DEPLOYMENT_NAME -n default
    REST_DEPLOYMENT_NAME=$(kubectl get deployments --no-headers=true | grep "^rest.*Init" | awk '{print $1}' | head -n 1)
    kubectl --kubeconfig="$KUBECONFIG_PATH" rollout restart deployment $REST_DEPLOYMENT_NAME -n default
    STORAGE_DEPLOYMENT_NAME=$(kubectl get deployments --no-headers=true | grep "^storage.*Init" | awk '{print $1}' | head -n 1)
    kubectl --kubeconfig="$KUBECONFIG_PATH" rollout restart deployment $STORAGE_DEPLOYMENT_NAME -n default
    STUDIO_DEPLOYMENT_NAME=$(kubectl get deployments --no-headers=true | grep "^studio.*Init" | awk '{print $1}' | head -n 1)
    kubectl --kubeconfig="$KUBECONFIG_PATH" rollout restart deployment $STUDIO_DEPLOYMENT_NAME -n default
    SUPAVISOR_DEPLOYMENT_NAME=$(kubectl get deployments --no-headers=true | grep "^supavisor.*Init" | awk '{print $1}' | head -n 1)
    kubectl --kubeconfig="$KUBECONFIG_PATH" rollout restart deployment $SUPAVISOR_DEPLOYMENT_NAME -n default
    VECTOR_DEPLOYMENT_NAME=$(kubectl get deployments --no-headers=true | grep "^vector.*Init" | awk '{print $1}' | head -n 1)
    kubectl --kubeconfig="$KUBECONFIG_PATH" rollout restart deployment $VECTOR_DEPLOYMENT_NAME -n default
else
    echo "Skipping core stack"
fi

source ./setup_core.sh

if [[ "${STACK_ARRAY[@]}" =~ "ecommerce" ]]; then
    MEDUSA_SERVER_DEPLOYMENT_NAME=$(kubectl --kubeconfig="$KUBECONFIG_PATH" get deployments --no-headers=true | grep "^medusa-server.*Init" | awk '{print $1}' | head -n 1)
    kubectl --kubeconfig="$KUBECONFIG_PATH" rollout restart deployment $MEDUSA_SERVER_DEPLOYMENT_NAME -n default
    MEILISEARCH_DEPLOYMENT_NAME=$(kubectl --kubeconfig="$KUBECONFIG_PATH" get deployments --no-headers=true | grep "^meilisearch.*Init" | awk '{print $1}' | head -n 1)
    kubectl --kubeconfig="$KUBECONFIG_PATH" rollout restart deployment $MEILISEARCH_DEPLOYMENT_NAME -n default
    REDIS_DEPLOYMENT_NAME=$(kubectl --kubeconfig="$KUBECONFIG_PATH" get deployments --no-headers=true | grep "^redis.*Init" | awk '{print $1}' | head -n 1)
    kubectl --kubeconfig="$KUBECONFIG_PATH" rollout restart deployment $REDIS_DEPLOYMENT_NAME -n default
else
    echo "Skipping core stack"
fi

if [[ "${STACK_ARRAY[@]}" =~ "s3" ]]; then
    MINIO_DEPLOYMENT_NAME=$(kubectl --kubeconfig="$KUBECONFIG_PATH" get deployments --no-headers=true | grep "^minio.*Init" | awk '{print $1}' | head -n 1)
    kubectl --kubeconfig="$KUBECONFIG_PATH" rollout restart deployment $MINIO_DEPLOYMENT_NAME -n default
else
    echo "Skipping core stack"
fi

if [[ "${STACK_ARRAY[@]}" =~ "ai" ]]; then
    ETCD_DEPLOYMENT_NAME=$(kubectl --kubeconfig="$KUBECONFIG_PATH" get deployments --no-headers=true | grep "^etcd.*Init" | awk '{print $1}' | head -n 1)
    kubectl --kubeconfig="$KUBECONFIG_PATH" rollout restart deployment $ETCD_DEPLOYMENT_NAME -n default
    OLLAMA_DEPLOYMENT_NAME=$(kubectl --kubeconfig="$KUBECONFIG_PATH" get deployments --no-headers=true | grep "^ollama.*Init" | awk '{print $1}' | head -n 1)
    kubectl --kubeconfig="$KUBECONFIG_PATH" rollout restart deployment $OLLAMA_DEPLOYMENT_NAME -n default
    OPEN_WEBUI_DEPLOYMENT_NAME=$(kubectl --kubeconfig="$KUBECONFIG_PATH" get deployments --no-headers=true | grep "^open-webui.*Init" | awk '{print $1}' | head -n 1)
    kubectl --kubeconfig="$KUBECONFIG_PATH" rollout restart deployment $OPEN_WEBUI_DEPLOYMENT_NAME -n default
    OPENEDAI_SPEECH_SERVER_DEPLOYMENT_NAME=$(kubectl get deployments --no-headers=true | grep "^openedai-speech-server.*Init" | awk '{print $1}' | head -n 1)
    kubectl --kubeconfig="$KUBECONFIG_PATH" rollout restart deployment $OPENEDAI_SPEECH_SERVER_DEPLOYMENT_NAME -n default
    STANDALONE_DEPLOYMENT_NAME=$(kubectl --kubeconfig="$KUBECONFIG_PATH" get deployments --no-headers=true | grep "^standalone.*Init" | awk '{print $1}' | head -n 1)
    kubectl --kubeconfig="$KUBECONFIG_PATH" rollout restart deployment $STANDALONE_DEPLOYMENT_NAME -n default
else
    echo "Skipping ai stack"
fi

source ./setup_ai.sh

DASHBOARD_DEPLOYMENT_NAME=$(kubectl --kubeconfig="$KUBECONFIG_PATH" get deployments --no-headers=true | grep "^dashboard.*Init" | awk '{print $1}' | head -n 1)
kubectl --kubeconfig="$KUBECONFIG_PATH" rollout restart deployment $DASHBOARD_DEPLOYMENT_NAME -n kubernetes-dashboard
kubectl --kubeconfig="$KUBECONFIG_PATH" proxy &

echo 'Dashboard token:'
kubectl --kubeconfig="$KUBECONFIG_PATH" get secret admin-user -n kubernetes-dashboard -o jsonpath={".data.token"} | base64 -d

exit 0