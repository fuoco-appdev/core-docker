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
IFS=' ' read -ra STACK_ARRAY <<< "$STACKS"

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Path to the password file
HTPASSWD_FILE="../volumes/nginx/.htpasswd"

# Function to add or create user
add_user() {
    local username=$1
    local password=$2
    local create_flag=""

    # Check if the file exists
    if [ ! -f "$HTPASSWD_FILE" ]; then
        create_flag="-c"
    fi

    # Use htpasswd to add or create user with user input
    npx htpasswd $create_flag "$HTPASSWD_FILE" "$username"
}

if ! [ -e "$HTPASSWD_FILE" ]; then
    echo "Create NGINX user"
    read -p "Enter username (or press Enter to finish): " username
    # Securely read password
    read -s -p "Enter password for $username: " password
    echo  # Add a newline after password input for better UX
        
    # Add or create user
    add_user "$username" "$password"

    echo "User $username added to $HTPASSWD_FILE"
fi

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


# Check if an argument (config file path) is provided
if [ -n "$1" ]; then
    KUBECONFIG_PATH="$1"
else
    KUBECONFIG_PATH=""
fi

kubectl --kubeconfig="$KUBECONFIG_PATH" delete secret env-secrets --ignore-not-found
kubectl --kubeconfig="$KUBECONFIG_PATH" create secret generic env-secrets --from-env-file=../.env

# Check if the directory exists, if not, create it
if [ ! -d "./release" ]; then
    mkdir -p "./release"
    echo "Directory ./release created."
else 
    echo "Directory ./release already exists."
fi

envsubst < Chart.tpl.yaml > Chart.yaml
envsubst < values.tpl.yaml > values.yaml

helm template "$PROJECT_NAME" "." --show-only "templates/nginx-config-persistentvolumeclaim.yaml" > release/nginx-config-persistentvolumeclaim.yaml
kubectl --kubeconfig="$KUBECONFIG_PATH" apply -f release/nginx-config-persistentvolumeclaim.yaml

helm template "$PROJECT_NAME" "." --show-only "templates/nginx-service.yaml" > release/nginx-service.yaml
kubectl --kubeconfig="$KUBECONFIG_PATH" apply -f release/nginx-service.yaml

helm template "$PROJECT_NAME" "." --show-only "templates/nginx-deployment.yaml" > release/nginx-deployment.yaml
kubectl --kubeconfig="$KUBECONFIG_PATH" apply -f release/nginx-deployment.yaml

# Copy files to the pod
echo "Copying files to the pod..."
NGINX_POD_NAME=$(kubectl --kubeconfig="$KUBECONFIG_PATH" get pods --no-headers=true | grep "^nginx.*Init" | awk '{print $1}' | head -n 1)
NAMESPACE="default"
TIMEOUT=30

if [[ -z "$NGINX_POD_NAME" ]]; then
    echo "No pod found with label service=nginx"
else
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

    export host="\$host" server_port="\$server_port" http_x_csrf_token="\$http_x_csrf_token" http_authorization="\$http_authorization" http_cookie="\$http_cookie" remote_addr="\$remote_addr" proxy_add_x_forwarded_for="\$proxy_add_x_forwarded_for" scheme="\$scheme" http_upgrade="\$http_upgrade" connection_upgrade="\$connection_upgrade"

    if [[ "${STACK_ARRAY[@]}" =~ "core" ]]; then
        envsubst < ../volumes/nginx/conf.d/core.conf.template > ../volumes/nginx/conf.d/core.conf
        kubectl --kubeconfig="$KUBECONFIG_PATH" cp ../volumes/nginx/conf.d/core.conf $NGINX_POD_NAME:/tmp/etc/nginx/conf.d/core.conf -c init-nginx
        export NGINX_CORE_CONFIG="include /etc/nginx/conf.d/core.conf;"
    else
        echo "Skipping nginx core config"
    fi

    if [[ "${STACK_ARRAY[@]}" =~ "ecommerce" ]]; then
        envsubst < ../volumes/nginx/conf.d/ecommerce.conf.template > ../volumes/nginx/conf.d/ecommerce.conf
        kubectl --kubeconfig="$KUBECONFIG_PATH" cp ../volumes/nginx/conf.d/ecommerce.conf $NGINX_POD_NAME:/tmp/etc/nginx/conf.d/ecommerce.conf -c init-nginx
        export NGINX_ECOMMERCE_CONFIG="include /etc/nginx/conf.d/ecommerce.conf;"
    else
        echo "Skipping nginx ecommerce config"
    fi

    if [[ "${STACK_ARRAY[@]}" =~ "ai" ]]; then
        envsubst < ../volumes/nginx/conf.d/ai.conf.template > ../volumes/nginx/conf.d/ai.conf
        kubectl --kubeconfig="$KUBECONFIG_PATH" cp ../volumes/nginx/conf.d/ai.conf $NGINX_POD_NAME:/tmp/etc/nginx/conf.d/ai.conf -c init-nginx
        export NGINX_AI_CONFIG="include /etc/nginx/conf.d/ai.conf;"
    else
        echo "Skipping nginx ai config"
    fi

    envsubst < ../volumes/nginx/nginx.conf.template > ../volumes/nginx/nginx.conf
    kubectl --kubeconfig="$KUBECONFIG_PATH" cp ../volumes/nginx/nginx.conf $NGINX_POD_NAME:/tmp/etc/nginx/nginx.conf -c init-nginx
    kubectl --kubeconfig="$KUBECONFIG_PATH" cp ../volumes/nginx/.htpasswd $NGINX_POD_NAME:/tmp/etc/nginx/.htpasswd -c init-nginx
fi

if [[ "${STACK_ARRAY[@]}" =~ "ai" ]]; then
    helm  template "$PROJECT_NAME" "." --show-only "templates/nvidia-device-plugin-daemonset.yaml" > release/nvidia-device-plugin-daemonset.yaml
    kubectl --kubeconfig="$KUBECONFIG_PATH" apply -f release/nvidia-device-plugin-daemonset.yaml
else
    echo "Skipping nvidia-device-plugin-daemonset.yaml deployment"
fi

# Deploy services based on STACKS
for stack in "${STACK_ARRAY[@]}"; do
    stack_paths=$(find ./templates -type f -name "${stack}-*")
    for path in $stack_paths; do
        filename=$(basename "$path")
        helm template "$PROJECT_NAME" "." --show-only "templates/$filename" > release/$filename
        envsubst < release/$filename | kubectl --kubeconfig="$KUBECONFIG_PATH" apply -f - 
    done
done

if [[ "${STACK_ARRAY[@]}" =~ "core" ]]; then
    # Copy files to the pod
    echo "Copying files to the pod..."
    NAMESPACE="default"
    TIMEOUT=300
    DB_POD_NAME=$(kubectl --kubeconfig="$KUBECONFIG_PATH" get pods --no-headers=true | grep "^db.*Init" | awk '{print $1}' | head -n 1)
    if [[ -z "$DB_POD_NAME" ]]; then
        echo "No pod found with label service=db"
    else
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
    fi

    KONG_POD_NAME=$(kubectl --kubeconfig="$KUBECONFIG_PATH" get pods --no-headers=true | grep "^kong.*Init" | awk '{print $1}' | head -n 1)
    if [[ -z "$KONG_POD_NAME" ]]; then
        echo "No pod found with label service=kong"
    else
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

        # Copy files to kong service
        kubectl --kubeconfig="$KUBECONFIG_PATH" cp ../volumes/api/kong.yml $KONG_POD_NAME:/tmp/home/kong/temp.yml -c init-kong
    fi

    SUPAVISOR_POD_NAME=$(kubectl --kubeconfig="$KUBECONFIG_PATH" get pods --no-headers=true | grep "^supavisor.*Init" | awk '{print $1}' | head -n 1)
    if [[ -z "$SUPAVISOR_POD_NAME" ]]; then
        echo "No pod found with label service=supavisor"
    else
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

        # Copy files to supavisor service
        kubectl --kubeconfig="$KUBECONFIG_PATH" cp ../volumes/pooler/pooler.exs $SUPAVISOR_POD_NAME:/tmp/etc/pooler/pooler.exs -c init-supavisor
    fi

    VECTOR_POD_NAME=$(kubectl --kubeconfig="$KUBECONFIG_PATH" get pods --no-headers=true | grep "^vector.*Init" | awk '{print $1}' | head -n 1)
    if [[ -z "$VECTOR_POD_NAME" ]]; then
        echo "No pod found with label service=vector"
    else
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
    
        kubectl --kubeconfig="$KUBECONFIG_PATH" cp ../volumes/logs/vector.yml $VECTOR_POD_NAME:/tmp/etc/vector/vector.yml -c init-vector
    fi

    ANALYTICS_POD_NAME=$(kubectl --kubeconfig="$KUBECONFIG_PATH" get pods --no-headers=true | grep "^analytics" | awk '{print $1}' | head -n 1)
    if [[ -z "$ANALYTICS_POD_NAME" ]]; then
        echo "No pod found with label service=analytics"
    else
        start_time=$(date +%s)
        while true; do
            # Check if the pod is running
            status=$(kubectl --kubeconfig="$KUBECONFIG_PATH" get pod $ANALYTICS_POD_NAME -n $NAMESPACE -o jsonpath='{.status.containerStatuses[*].state}')
            status_key=$(echo "$status" | sed 's/^{"\([^"]*\)":.*/\1/')
            if [ "$status_key" = "running" ]; then
                echo "Pod $ANALYTICS_POD_NAME is running"
                break
            else
                current_time=$(date +%s)
                elapsed_time=$((current_time - start_time))
                
                if [ $elapsed_time -ge $TIMEOUT ]; then
                    echo "Timeout: Pod $ANALYTICS_POD_NAME did not run within $TIMEOUT seconds"
                    break
                fi
                
                echo "Waiting for pod $ANALYTICS_POD_NAME to be running..."
                sleep 5 # Wait for 5 seconds before checking again
            fi
        done
    
        kubectl --kubeconfig="$KUBECONFIG_PATH" exec -it $ANALYTICS_POD_NAME -- sh -c "echo '127.0.0.1 $NGINX_LOGFLARE_HOST_URL' >> /etc/hosts"
    fi
else
    echo "Skipping core stack"
fi

if [[ "${STACK_ARRAY[@]}" =~ "ai" ]]; then
    OPENEDAI_SPEECH_SERVER_POD_NAME=$(kubectl --kubeconfig="$KUBECONFIG_PATH" get pods --no-headers=true | grep "^openedai-speech-server.*Init" | awk '{print $1}' | head -n 1)
    if [[ -z "$OPENEDAI_SPEECH_SERVER_POD_NAME" ]]; then
        echo "No pod found with label service=openedai-speech-server"
    else
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
    fi
else
    echo "Skipping ai stack"
fi

kubectl --kubeconfig="$KUBECONFIG_PATH" apply -f "https://raw.githubusercontent.com/kubernetes/dashboard/v2.7.0/aio/deploy/recommended.yaml"
kubectl --kubeconfig="$KUBECONFIG_PATH" proxy &

helm template "$PROJECT_NAME" "."  --show-only "templates/dashboard-adminuser.yaml" > release/dashboard-adminuser.yaml
kubectl --kubeconfig="$KUBECONFIG_PATH" apply -f release/dashboard-adminuser.yaml -n kubernetes-dashboard

helm template "$PROJECT_NAME" "." --show-only "templates/dashboard-clusterrole.yaml" > release/dashboard-clusterrole.yaml
kubectl --kubeconfig="$KUBECONFIG_PATH" apply -f release/dashboard-clusterrole.yaml -n kubernetes-dashboard

helm template "$PROJECT_NAME" "." --show-only "templates/dashboard-secret.yaml" > release/dashboard-secret.yaml
kubectl --kubeconfig="$KUBECONFIG_PATH" apply -f release/dashboard-secret.yaml -n kubernetes-dashboard

echo 'Dashboard token:'
kubectl --kubeconfig="$KUBECONFIG_PATH" get secret admin-user -n kubernetes-dashboard -o jsonpath={".data.token"} | base64 -d

exit 0