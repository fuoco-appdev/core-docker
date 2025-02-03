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

# Check if an argument (config file path) is provided
if [ -n "$1" ]; then
    KUBECONFIG_PATH="$1"
else
    KUBECONFIG_PATH=""
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

kubectl --kubeconfig="$KUBECONFIG_PATH" delete secret env-secrets --ignore-not-found
kubectl --kubeconfig="$KUBECONFIG_PATH" create secret generic env-secrets --from-env-file=../.env

NGINX_DEPLOYMENT_NAME=$(kubectl --kubeconfig="$KUBECONFIG_PATH" get deployments --no-headers=true | grep "^nginx" | awk '{print $1}' | head -n 1)
kubectl --kubeconfig="$KUBECONFIG_PATH" rollout restart deployment $NGINX_DEPLOYMENT_NAME -n default

# Copy files to the pod
echo "Copying files to the pod..."
NGINX_POD_NAME=$(kubectl --kubeconfig="$KUBECONFIG_PATH" get pods --no-headers=true | grep "^nginx" | awk '{print $1}' | head -n 1)
NAMESPACE="default"
TIMEOUT=30

start_time=$(date +%s)
while true; do
    # Check if the pod is running
    status=$(kubectl --kubeconfig="$KUBECONFIG_PATH" get pod $NGINX_POD_NAME -n $NAMESPACE -o jsonpath='{.status.initContainerStatuses[*].state}')
    status_key=$(echo "$status" | sed 's/^{"\([^"]*\)":.*/\1/')
    if [ "$status_key" = "running" ]; then
        echo "Pod $NGINX_POD_NAME is running"
        break
    else
        current_time=$(date +%s)
        elapsed_time=$((current_time - start_time))
            
        if [ $elapsed_time -ge $TIMEOUT ]; then
            echo "Timeout: Pod $NGINX_POD_NAME did not run within $TIMEOUT seconds"
            break
        fi
            
        echo "Waiting for pod $NGINX_POD_NAME to be running..."
        sleep 5 # Wait for 5 seconds before checking again
    fi
done

if [ -z "$NGINX_POD_NAME" ]; then
    echo "No pod found with label service=nginx"
    exit 1
fi

export host="\$host" remote_addr="\$remote_addr" proxy_add_x_forwarded_for="\$proxy_add_x_forwarded_for" scheme="\$scheme"
envsubst < ../volumes/nginx/nginx.conf.template > ../volumes/nginx/nginx.conf
kubectl --kubeconfig="$KUBECONFIG_PATH" cp ../volumes/nginx/nginx.conf $NGINX_POD_NAME:/tmp/etc/nginx/nginx.conf -c init-nginx

IFS=' ' read -ra STACK_ARRAY <<< "$STACKS"

if [[ "${STACK_ARRAY[@]}" =~ "core" ]]; then
    ANALYTICS_DEPLOYMENT_NAME=$(kubectl --kubeconfig="$KUBECONFIG_PATH" get deployments --no-headers=true | grep "^analytics" | awk '{print $1}' | head -n 1)
    kubectl --kubeconfig="$KUBECONFIG_PATH" rollout restart deployment $ANALYTICS_DEPLOYMENT_NAME -n default
    AUTH_DEPLOYMENT_NAME=$(kubectl --kubeconfig="$KUBECONFIG_PATH" get deployments --no-headers=true | grep "^auth" | awk '{print $1}' | head -n 1)
    kubectl --kubeconfig="$KUBECONFIG_PATH" rollout restart deployment $AUTH_DEPLOYMENT_NAME -n default
    DB_DEPLOYMENT_NAME=$(kubectl --kubeconfig="$KUBECONFIG_PATH" get deployments --no-headers=true | grep "^db" | awk '{print $1}' | head -n 1)
    kubectl --kubeconfig="$KUBECONFIG_PATH" rollout restart deployment $DB_DEPLOYMENT_NAME -n default
    IMGPROXY_DEPLOYMENT_NAME=$(kubectl --kubeconfig="$KUBECONFIG_PATH" get deployments --no-headers=true | grep "^imgproxy" | awk '{print $1}' | head -n 1)
    kubectl --kubeconfig="$KUBECONFIG_PATH" rollout restart deployment $IMGPROXY_DEPLOYMENT_NAME -n default
    KONG_DEPLOYMENT_NAME=$(kubectl --kubeconfig="$KUBECONFIG_PATH" get deployments --no-headers=true | grep "^kong" | awk '{print $1}' | head -n 1)
    kubectl --kubeconfig="$KUBECONFIG_PATH" rollout restart deployment $KONG_DEPLOYMENT_NAME -n default
    META_DEPLOYMENT_NAME=$(kubectl --kubeconfig="$KUBECONFIG_PATH" get deployments --no-headers=true | grep "^meta" | awk '{print $1}' | head -n 1)
    kubectl --kubeconfig="$KUBECONFIG_PATH" rollout restart deployment $META_DEPLOYMENT_NAME -n default
    REALTIME_DEPLOYMENT_NAME=$(kubectl get deployments --no-headers=true | grep "^realtime" | awk '{print $1}' | head -n 1)
    kubectl --kubeconfig="$KUBECONFIG_PATH" rollout restart deployment $REALTIME_DEPLOYMENT_NAME -n default
    REST_DEPLOYMENT_NAME=$(kubectl get deployments --no-headers=true | grep "^rest" | awk '{print $1}' | head -n 1)
    kubectl --kubeconfig="$KUBECONFIG_PATH" rollout restart deployment $REST_DEPLOYMENT_NAME -n default
    STORAGE_DEPLOYMENT_NAME=$(kubectl get deployments --no-headers=true | grep "^storage" | awk '{print $1}' | head -n 1)
    kubectl --kubeconfig="$KUBECONFIG_PATH" rollout restart deployment $STORAGE_DEPLOYMENT_NAME -n default
    STUDIO_DEPLOYMENT_NAME=$(kubectl get deployments --no-headers=true | grep "^studio" | awk '{print $1}' | head -n 1)
    kubectl --kubeconfig="$KUBECONFIG_PATH" rollout restart deployment $STUDIO_DEPLOYMENT_NAME -n default
    SUPAVISOR_DEPLOYMENT_NAME=$(kubectl get deployments --no-headers=true | grep "^supavisor" | awk '{print $1}' | head -n 1)
    kubectl --kubeconfig="$KUBECONFIG_PATH" rollout restart deployment $SUPAVISOR_DEPLOYMENT_NAME -n default
    VECTOR_DEPLOYMENT_NAME=$(kubectl get deployments --no-headers=true | grep "^vector" | awk '{print $1}' | head -n 1)
    kubectl --kubeconfig="$KUBECONFIG_PATH" rollout restart deployment $VECTOR_DEPLOYMENT_NAME -n default

    # Copy files to the pod
    echo "Copying files to the pod..."
    DB_POD_NAME=$(kubectl --kubeconfig="$KUBECONFIG_PATH" get pods --no-headers=true | grep "^db" | awk '{print $1}' | head -n 1)
    NAMESPACE="default"
    TIMEOUT=30

    start_time=$(date +%s)
    while true; do
        # Check if the pod is running
        status=$(kubectl --kubeconfig="$KUBECONFIG_PATH" get pod $DB_POD_NAME -n $NAMESPACE -o jsonpath='{.status.initContainerStatuses[*].state}')
        status_key=$(echo "$status" | sed 's/^{"\([^"]*\)":.*/\1/')
        if [ "$status_key" = "running" ]; then
            echo "Pod $DB_POD_NAME is running"
            break
        else
            current_time=$(date +%s)
            elapsed_time=$((current_time - start_time))
            
            if [ $elapsed_time -ge $TIMEOUT ]; then
                echo "Timeout: Pod $DB_POD_NAME did not run within $TIMEOUT seconds"
                break
            fi
            
            echo "Waiting for pod $DB_POD_NAME to be running..."
            sleep 5 # Wait for 5 seconds before checking again
        fi
    done

    if [ -z "$DB_POD_NAME" ]; then
        echo "No pod found with label service=db"
        exit 1
    fi

    # Copy files to db service
    # kubectl --kubeconfig="$KUBECONFIG_PATH" cp ../volumes/db/data/ $DB_POD_NAME:/tmp/var/lib/postgresql -c init-db
    kubectl --kubeconfig="$KUBECONFIG_PATH" cp ../volumes/db/server.crt $DB_POD_NAME:/tmp/var/lib/ssl/server.crt -c init-db
    kubectl --kubeconfig="$KUBECONFIG_PATH" cp ../volumes/db/server.key $DB_POD_NAME:/tmp/var/lib/ssl/server.key -c init-db
    kubectl --kubeconfig="$KUBECONFIG_PATH" cp ../volumes/db/realtime.sql $DB_POD_NAME:/tmp/docker-entrypoint-initdb.d/migrations/99-realtime.sql -c init-db
    kubectl --kubeconfig="$KUBECONFIG_PATH" cp ../volumes/db/webhooks.sql $DB_POD_NAME:/tmp/docker-entrypoint-initdb.d/init-scripts/98-webhooks.sql -c init-db
    kubectl --kubeconfig="$KUBECONFIG_PATH" cp ../volumes/db/roles.sql $DB_POD_NAME:/tmp/docker-entrypoint-initdb.d/init-scripts/99-roles.sql -c init-db
    kubectl --kubeconfig="$KUBECONFIG_PATH" cp ../volumes/db/jwt.sql $DB_POD_NAME:/tmp/docker-entrypoint-initdb.d/init-scripts/99-jwt.sql -c init-db
    kubectl --kubeconfig="$KUBECONFIG_PATH" cp ../volumes/db/_supabase.sql $DB_POD_NAME:/tmp/docker-entrypoint-initdb.d/migrations/97-_supabase.sql -c init-db
    kubectl --kubeconfig="$KUBECONFIG_PATH" cp ../volumes/db/logs.sql $DB_POD_NAME:/tmp/docker-entrypoint-initdb.d/migrations/99-logs.sql -c init-db
    kubectl --kubeconfig="$KUBECONFIG_PATH" cp ../volumes/db/pooler.sql $DB_POD_NAME:/tmp/docker-entrypoint-initdb.d/migrations/99-pooler.sql -c init-db

    KONG_POD_NAME=$(kubectl --kubeconfig="$KUBECONFIG_PATH" get pods --no-headers=true | grep "^kong" | awk '{print $1}' | head -n 1)
    start_time=$(date +%s)
    while true; do
        # Check if the pod is running
        status=$(kubectl --kubeconfig="$KUBECONFIG_PATH" get pod $KONG_POD_NAME -n $NAMESPACE -o jsonpath='{.status.initContainerStatuses[*].state}')
        status_key=$(echo "$status" | sed 's/^{"\([^"]*\)":.*/\1/')
        if [ "$status_key" = "running" ]; then
            echo "Pod $KONG_POD_NAME is running"
            break
        else
            current_time=$(date +%s)
            elapsed_time=$((current_time - start_time))
            
            if [ $elapsed_time -ge $TIMEOUT ]; then
                echo "Timeout: Pod $KONG_POD_NAME did not run within $TIMEOUT seconds"
                break
            fi
            
            echo "Waiting for pod $KONG_POD_NAME to be running..."
            sleep 5 # Wait for 5 seconds before checking again
        fi
    done

    if [ -z "$KONG_POD_NAME" ]; then
        echo "No pod found with label service=kong"
        exit 1
    fi

    # Copy files to kong service
    kubectl --kubeconfig="$KUBECONFIG_PATH" cp ../volumes/api/kong.yml $KONG_POD_NAME:/tmp/home/kong/temp.yml -c init-kong

    SUPAVISOR_POD_NAME=$(kubectl --kubeconfig="$KUBECONFIG_PATH" get pods --no-headers=true | grep "^supavisor" | awk '{print $1}' | head -n 1)
    start_time=$(date +%s)
    while true; do
        # Check if the pod is running
        status=$(kubectl --kubeconfig="$KUBECONFIG_PATH" get pod $SUPAVISOR_POD_NAME -n $NAMESPACE -o jsonpath='{.status.initContainerStatuses[*].state}')
        status_key=$(echo "$status" | sed 's/^{"\([^"]*\)":.*/\1/')
        if [ "$status_key" = "running" ]; then
            echo "Pod $SUPAVISOR_POD_NAME is running"
            break
        else
            current_time=$(date +%s)
            elapsed_time=$((current_time - start_time))
            
            if [ $elapsed_time -ge $TIMEOUT ]; then
                echo "Timeout: Pod $SUPAVISOR_POD_NAME did not run within $TIMEOUT seconds"
                break
            fi
            
            echo "Waiting for pod $SUPAVISOR_POD_NAME to be running..."
            sleep 5 # Wait for 5 seconds before checking again
        fi
    done

    if [ -z "$SUPAVISOR_POD_NAME" ]; then
        echo "No pod found with label service=supavisor"
        exit 1
    fi

    # Copy files to supavisor service
    kubectl --kubeconfig="$KUBECONFIG_PATH" cp ../volumes/pooler/pooler.exs $SUPAVISOR_POD_NAME:/tmp/etc/pooler/pooler.exs -c init-supavisor

    VECTOR_POD_NAME=$(kubectl --kubeconfig="$KUBECONFIG_PATH" get pods --no-headers=true | grep "^vector" | awk '{print $1}' | head -n 1)
    start_time=$(date +%s)
    while true; do
        # Check if the pod is running
        status=$(kubectl --kubeconfig="$KUBECONFIG_PATH" get pod $VECTOR_POD_NAME -n $NAMESPACE -o jsonpath='{.status.initContainerStatuses[*].state}')
        status_key=$(echo "$status" | sed 's/^{"\([^"]*\)":.*/\1/')
        if [ "$status_key" = "running" ]; then
            echo "Pod $VECTOR_POD_NAME is running"
            break
        else
            current_time=$(date +%s)
            elapsed_time=$((current_time - start_time))
            
            if [ $elapsed_time -ge $TIMEOUT ]; then
                echo "Timeout: Pod $VECTOR_POD_NAME did not run within $TIMEOUT seconds"
                break
            fi
            
            echo "Waiting for pod $VECTOR_POD_NAME to be running..."
            sleep 5 # Wait for 5 seconds before checking again
        fi
    done

    if [ -z "$VECTOR_POD_NAME" ]; then
        echo "No pod found with label service=vector"
        exit 1
    fi

    kubectl --kubeconfig="$KUBECONFIG_PATH" cp ../volumes/logs/vector.yml $VECTOR_POD_NAME:/tmp/etc/vector/vector.yml -c init-vector
else
    echo "Skipping core stack"
fi

if [[ "${STACK_ARRAY[@]}" =~ "ecommerce" ]]; then
    MEDUSA_SERVER_DEPLOYMENT_NAME=$(kubectl --kubeconfig="$KUBECONFIG_PATH" get deployments --no-headers=true | grep "^medusa-server" | awk '{print $1}' | head -n 1)
    kubectl --kubeconfig="$KUBECONFIG_PATH" rollout restart deployment $MEDUSA_SERVER_DEPLOYMENT_NAME -n default
    MEILISEARCH_DEPLOYMENT_NAME=$(kubectl --kubeconfig="$KUBECONFIG_PATH" get deployments --no-headers=true | grep "^meilisearch" | awk '{print $1}' | head -n 1)
    kubectl --kubeconfig="$KUBECONFIG_PATH" rollout restart deployment $MEILISEARCH_DEPLOYMENT_NAME -n default
    REDIS_DEPLOYMENT_NAME=$(kubectl --kubeconfig="$KUBECONFIG_PATH" get deployments --no-headers=true | grep "^redis" | awk '{print $1}' | head -n 1)
    kubectl --kubeconfig="$KUBECONFIG_PATH" rollout restart deployment $REDIS_DEPLOYMENT_NAME -n default
else
    echo "Skipping core stack"
fi

if [[ "${STACK_ARRAY[@]}" =~ "s3" ]]; then
    MINIO_DEPLOYMENT_NAME=$(kubectl --kubeconfig="$KUBECONFIG_PATH" get deployments --no-headers=true | grep "^minio" | awk '{print $1}' | head -n 1)
    kubectl --kubeconfig="$KUBECONFIG_PATH" rollout restart deployment $MINIO_DEPLOYMENT_NAME -n default
else
    echo "Skipping core stack"
fi

if [[ "${STACK_ARRAY[@]}" =~ "ai" ]]; then
    ETCD_DEPLOYMENT_NAME=$(kubectl --kubeconfig="$KUBECONFIG_PATH" get deployments --no-headers=true | grep "^etcd" | awk '{print $1}' | head -n 1)
    kubectl --kubeconfig="$KUBECONFIG_PATH" rollout restart deployment $ETCD_DEPLOYMENT_NAME -n default
    OLLAMA_DEPLOYMENT_NAME=$(kubectl --kubeconfig="$KUBECONFIG_PATH" get deployments --no-headers=true | grep "^ollama" | awk '{print $1}' | head -n 1)
    kubectl --kubeconfig="$KUBECONFIG_PATH" rollout restart deployment $OLLAMA_DEPLOYMENT_NAME -n default
    OPEN_WEBUI_DEPLOYMENT_NAME=$(kubectl --kubeconfig="$KUBECONFIG_PATH" get deployments --no-headers=true | grep "^open-webui" | awk '{print $1}' | head -n 1)
    kubectl --kubeconfig="$KUBECONFIG_PATH" rollout restart deployment $OPEN_WEBUI_DEPLOYMENT_NAME -n default
    OPENEDAI_SPEECH_SERVER_DEPLOYMENT_NAME=$(kubectl get deployments --no-headers=true | grep "^openedai-speech-server" | awk '{print $1}' | head -n 1)
    kubectl --kubeconfig="$KUBECONFIG_PATH" rollout restart deployment $OPENEDAI_SPEECH_SERVER_DEPLOYMENT_NAME -n default
    STANDALONE_DEPLOYMENT_NAME=$(kubectl --kubeconfig="$KUBECONFIG_PATH" get deployments --no-headers=true | grep "^standalone" | awk '{print $1}' | head -n 1)
    kubectl --kubeconfig="$KUBECONFIG_PATH" rollout restart deployment $STANDALONE_DEPLOYMENT_NAME -n default

    OPENEDAI_SPEECH_SERVER_POD_NAME=$(kubectl --kubeconfig="$KUBECONFIG_PATH" get pods --no-headers=true | grep "^openedai-speech-server" | awk '{print $1}' | head -n 1)
    start_time=$(date +%s)
    while true; do
        # Check if the pod is running
        status=$(kubectl --kubeconfig="$KUBECONFIG_PATH" get pod $OPENEDAI_SPEECH_SERVER_POD_NAME -n $NAMESPACE -o jsonpath='{.status.initContainerStatuses[*].state}')
        status_key=$(echo "$status" | sed 's/^{"\([^"]*\)":.*/\1/')
        if [ "$status_key" = "running" ]; then
            echo "Pod $OPENEDAI_SPEECH_SERVER_POD_NAME is running"
            break
        else
            current_time=$(date +%s)
            elapsed_time=$((current_time - start_time))
            
            if [ $elapsed_time -ge $TIMEOUT ]; then
                echo "Timeout: Pod $OPENEDAI_SPEECH_SERVER_POD_NAME did not run within $TIMEOUT seconds"
                break
            fi
            
            echo "Waiting for pod $OPENEDAI_SPEECH_SERVER_POD_NAME to be running..."
            sleep 5 # Wait for 5 seconds before checking again
        fi
    done

    if [ -z "$OPENEDAI_SPEECH_SERVER_POD_NAME" ]; then
        echo "No pod found with label service=openedai-speech-server"
        exit 1
    fi

    kubectl --kubeconfig="$KUBECONFIG_PATH" cp ../../openedai-speech/voices/onyx.wav $OPENEDAI_SPEECH_SERVER_POD_NAME:/app/voices/onyx.wav -c init-openedai-speech-server
    kubectl --kubeconfig="$KUBECONFIG_PATH" cp ../../openedai-speech/voices/nova.wav $OPENEDAI_SPEECH_SERVER_POD_NAME:/app/voices/nova.wav -c init-openedai-speech-server
    kubectl --kubeconfig="$KUBECONFIG_PATH" cp ../../openedai-speech/voices/fable.wav $OPENEDAI_SPEECH_SERVER_POD_NAME:/app/voices/fable.wav -c init-openedai-speech-server
    kubectl --kubeconfig="$KUBECONFIG_PATH" cp ../../openedai-speech/voices/en_US-libritts_r-medium.onnx $OPENEDAI_SPEECH_SERVER_POD_NAME:/app/voices/en_US-libritts_r-medium.onnx -c init-openedai-speech-server
    kubectl --kubeconfig="$KUBECONFIG_PATH" cp ../../openedai-speech/voices/en_GB-northern_english_male-medium.onnx $OPENEDAI_SPEECH_SERVER_POD_NAME:/app/voices/en_GB-northern_english_male-medium.onnx -c init-openedai-speech-server
    kubectl --kubeconfig="$KUBECONFIG_PATH" cp ../../openedai-speech/voices/en_GB-northern_english_male-medium.onnx.json $OPENEDAI_SPEECH_SERVER_POD_NAME:/app/voices/en_GB-northern_english_male-medium.onnx.json -c init-openedai-speech-server
    kubectl --kubeconfig="$KUBECONFIG_PATH" cp ../../openedai-speech/voices/echo.wav $OPENEDAI_SPEECH_SERVER_POD_NAME:/app/voices/echo.wav -c init-openedai-speech-server
    kubectl --kubeconfig="$KUBECONFIG_PATH" cp ../../openedai-speech/voices/alloy.wav $OPENEDAI_SPEECH_SERVER_POD_NAME:/app/voices/alloy.wav -c init-openedai-speech-server
    kubectl --kubeconfig="$KUBECONFIG_PATH" cp ../../openedai-speech/voices/alloy-alt.wav $OPENEDAI_SPEECH_SERVER_POD_NAME:/app/voices/alloy-alt.wav -c init-openedai-speech-server
    kubectl --kubeconfig="$KUBECONFIG_PATH" cp ../../openedai-speech/voices/shimmer.wav $OPENEDAI_SPEECH_SERVER_POD_NAME:/app/voices/shimmer.wav -c init-openedai-speech-server
    kubectl --kubeconfig="$KUBECONFIG_PATH" cp ../../openedai-speech/config/config_files_will_go_here.txt $OPENEDAI_SPEECH_SERVER_POD_NAME:/app/config/config_files_will_go_here.txt -c init-openedai-speech-server
    kubectl --kubeconfig="$KUBECONFIG_PATH" cp ../../openedai-speech/config/pre_process_map.yaml $OPENEDAI_SPEECH_SERVER_POD_NAME:/app/config/pre_process_map.yaml -c init-openedai-speech-server
    kubectl --kubeconfig="$KUBECONFIG_PATH" cp ../../openedai-speech/config/voice_to_speaker.yaml $OPENEDAI_SPEECH_SERVER_POD_NAME:/app/config/voice_to_speaker.yaml -c init-openedai-speech-server
else
    echo "Skipping ai stack"
fi

DASHBOARD_DEPLOYMENT_NAME=$(kubectl --kubeconfig="$KUBECONFIG_PATH" get deployments --no-headers=true | grep "^dashboard" | awk '{print $1}' | head -n 1)
kubectl --kubeconfig="$KUBECONFIG_PATH" rollout restart deployment $DASHBOARD_DEPLOYMENT_NAME -n kubernetes-dashboard
kubectl --kubeconfig="$KUBECONFIG_PATH" proxy &

echo 'Dashboard token:'
kubectl --kubeconfig="$KUBECONFIG_PATH" get secret admin-user -n kubernetes-dashboard -o jsonpath={".data.token"} | base64 -d

exit 0