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
kubectl apply -f release/nginx-config-persistentvolumeclaim.yaml

helm template "$PROJECT_NAME" "." --show-only "templates/nginx-deployment.yaml" > release/nginx-deployment.yaml
kubectl apply -f release/nginx-deployment.yaml

# Copy files to the pod
echo "Copying files to the nginx pod..."
NGINX_POD_NAME=$(kubectl get pods --no-headers=true | grep "^nginx" | awk '{print $1}' | head -n 1)
kubectl wait --for=condition=Ready pod/$NGINX_POD_NAME --timeout=60s
kubectl cp <(envsubst < ../volumes/nginx/nginx.conf.template) $NGINX_POD_NAME:/etc/nginx/nginx.conf -c init-nginx

IFS=' ' read -ra STACK_ARRAY <<< "$STACKS"

if [[ "${STACK_ARRAY[@]}" =~ "ai" ]]; then
    helm  template "$PROJECT_NAME" "." --show-only "templates/nvidia-device-plugin-daemonset.yaml" > release/nvidia-device-plugin-daemonset.yaml
    kubectl apply -f release/nvidia-device-plugin-daemonset.yaml
else
    echo "Skipping nvidia-device-plugin-daemonset.yaml deployment"
fi

# Deploy services based on STACKS
for stack in "${STACK_ARRAY[@]}"; do
    stack_paths=$(find ./templates -type f -name "${stack}-*")
    for path in $stack_paths; do
        filename=$(basename "$path")
        helm template "$PROJECT_NAME" "." --show-only "templates/$filename" > release/$filename
        kubectl apply -f release/$filename
    done
done

if [[ "${STACK_ARRAY[@]}" =~ "core" ]]; then
    # Copy files to the pod
    echo "Copying files to the pod..."
    DB_POD_NAME=$(kubectl get pods --no-headers=true | grep "^db" | awk '{print $1}' | head -n 1)
    NAMESPACE="default"
    TIMEOUT=3000

    start_time=$(date +%s)
    while true; do
        # Check if the pod is running
        status=$(kubectl get pod $DB_POD_NAME -n $NAMESPACE -o jsonpath='{.status.initContainerStatuses[*].state}')
        status_key=$(echo "$status" | sed 's/^{"\([^"]*\)":.*/\1/')
        if [ "$status_key" = "running" ]; then
            echo "Pod $DB_POD_NAME is running"
            break
        else
            current_time=$(date +%s)
            elapsed_time=$((current_time - start_time))
            
            if [ $elapsed_time -ge $TIMEOUT ]; then
                echo "Timeout: Pod $DB_POD_NAME did not run within $TIMEOUT seconds"
                exit 1
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
    # kubectl cp ../volumes/db/data/ $DB_POD_NAME:/tmp/var/lib/postgresql -c init-db
    kubectl cp ../volumes/db/server.crt $DB_POD_NAME:/tmp/var/lib/ssl/server.crt -c init-db
    kubectl cp ../volumes/db/server.key $DB_POD_NAME:/tmp/var/lib/ssl/server.key -c init-db
    kubectl cp ../volumes/db/realtime.sql $DB_POD_NAME:/tmp/docker-entrypoint-initdb.d/migrations/99-realtime.sql -c init-db
    kubectl cp ../volumes/db/webhooks.sql $DB_POD_NAME:/tmp/docker-entrypoint-initdb.d/init-scripts/98-webhooks.sql -c init-db
    kubectl cp ../volumes/db/roles.sql $DB_POD_NAME:/tmp/docker-entrypoint-initdb.d/init-scripts/99-roles.sql -c init-db
    kubectl cp ../volumes/db/jwt.sql $DB_POD_NAME:/tmp/docker-entrypoint-initdb.d/init-scripts/99-jwt.sql -c init-db
    kubectl cp ../volumes/db/_supabase.sql $DB_POD_NAME:/tmp/docker-entrypoint-initdb.d/migrations/97-_supabase.sql -c init-db
    kubectl cp ../volumes/db/logs.sql $DB_POD_NAME:/tmp/docker-entrypoint-initdb.d/migrations/99-logs.sql -c init-db
    kubectl cp ../volumes/db/pooler.sql $DB_POD_NAME:/tmp/docker-entrypoint-initdb.d/migrations/99-pooler.sql -c init-db

    KONG_POD_NAME=$(kubectl get pods --no-headers=true | grep "^kong" | awk '{print $1}' | head -n 1)
    start_time=$(date +%s)
    while true; do
        # Check if the pod is running
        status=$(kubectl get pod $KONG_POD_NAME -n $NAMESPACE -o jsonpath='{.status.initContainerStatuses[*].state}')
        status_key=$(echo "$status" | sed 's/^{"\([^"]*\)":.*/\1/')
        if [ "$status_key" = "running" ]; then
            echo "Pod $KONG_POD_NAME is running"
            break
        else
            current_time=$(date +%s)
            elapsed_time=$((current_time - start_time))
            
            if [ $elapsed_time -ge $TIMEOUT ]; then
                echo "Timeout: Pod $KONG_POD_NAME did not run within $TIMEOUT seconds"
                exit 1
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
    kubectl cp ../volumes/api/kong.yml $KONG_POD_NAME:/tmp/home/kong/temp.yml -c init-kong

    SUPAVISOR_POD_NAME=$(kubectl get pods --no-headers=true | grep "^supavisor" | awk '{print $1}' | head -n 1)
    start_time=$(date +%s)
    while true; do
        # Check if the pod is running
        status=$(kubectl get pod $SUPAVISOR_POD_NAME -n $NAMESPACE -o jsonpath='{.status.initContainerStatuses[*].state}')
        status_key=$(echo "$status" | sed 's/^{"\([^"]*\)":.*/\1/')
        if [ "$status_key" = "running" ]; then
            echo "Pod $SUPAVISOR_POD_NAME is running"
            break
        else
            current_time=$(date +%s)
            elapsed_time=$((current_time - start_time))
            
            if [ $elapsed_time -ge $TIMEOUT ]; then
                echo "Timeout: Pod $SUPAVISOR_POD_NAME did not run within $TIMEOUT seconds"
                exit 1
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
    kubectl cp ../volumes/pooler/pooler.exs $SUPAVISOR_POD_NAME:/tmp/etc/pooler/pooler.exs -c init-supavisor

    VECTOR_POD_NAME=$(kubectl get pods --no-headers=true | grep "^vector" | awk '{print $1}' | head -n 1)
    start_time=$(date +%s)
    while true; do
        # Check if the pod is running
        status=$(kubectl get pod $VECTOR_POD_NAME -n $NAMESPACE -o jsonpath='{.status.initContainerStatuses[*].state}')
        status_key=$(echo "$status" | sed 's/^{"\([^"]*\)":.*/\1/')
        if [ "$status_key" = "running" ]; then
            echo "Pod $VECTOR_POD_NAME is running"
            break
        else
            current_time=$(date +%s)
            elapsed_time=$((current_time - start_time))
            
            if [ $elapsed_time -ge $TIMEOUT ]; then
                echo "Timeout: Pod $VECTOR_POD_NAME did not run within $TIMEOUT seconds"
                exit 1
            fi
            
            echo "Waiting for pod $VECTOR_POD_NAME to be running..."
            sleep 5 # Wait for 5 seconds before checking again
        fi
    done

    if [ -z "$VECTOR_POD_NAME" ]; then
        echo "No pod found with label service=vector"
        exit 1
    fi

    kubectl cp ../volumes/logs/vector.yml $VECTOR_POD_NAME:/tmp/etc/vector/vector.yml -c init-vector
else
    echo "Skipping core stack"
fi

if [[ "${STACK_ARRAY[@]}" =~ "ai" ]]; then
    OPENEDAI_SPEECH_SERVER_POD_NAME=$(kubectl get pods --no-headers=true | grep "^openedai-speech-server" | awk '{print $1}' | head -n 1)
    start_time=$(date +%s)
    while true; do
        # Check if the pod is running
        status=$(kubectl get pod $OPENEDAI_SPEECH_SERVER_POD_NAME -n $NAMESPACE -o jsonpath='{.status.initContainerStatuses[*].state}')
        status_key=$(echo "$status" | sed 's/^{"\([^"]*\)":.*/\1/')
        if [ "$status_key" = "running" ]; then
            echo "Pod $OPENEDAI_SPEECH_SERVER_POD_NAME is running"
            break
        else
            current_time=$(date +%s)
            elapsed_time=$((current_time - start_time))
            
            if [ $elapsed_time -ge $TIMEOUT ]; then
                echo "Timeout: Pod $OPENEDAI_SPEECH_SERVER_POD_NAME did not run within $TIMEOUT seconds"
                exit 1
            fi
            
            echo "Waiting for pod $OPENEDAI_SPEECH_SERVER_POD_NAME to be running..."
            sleep 5 # Wait for 5 seconds before checking again
        fi
    done

    if [ -z "$OPENEDAI_SPEECH_SERVER_POD_NAME" ]; then
        echo "No pod found with label service=openedai-speech-server"
        exit 1
    fi

    kubectl cp ../../openedai-speech/voices/onyx.wav $OPENEDAI_SPEECH_SERVER_POD_NAME:/app/voices/onyx.wav -c init-openedai-speech-server
    kubectl cp ../../openedai-speech/voices/nova.wav $OPENEDAI_SPEECH_SERVER_POD_NAME:/app/voices/nova.wav -c init-openedai-speech-server
    kubectl cp ../../openedai-speech/voices/fable.wav $OPENEDAI_SPEECH_SERVER_POD_NAME:/app/voices/fable.wav -c init-openedai-speech-server
    kubectl cp ../../openedai-speech/voices/en_US-libritts_r-medium.onnx $OPENEDAI_SPEECH_SERVER_POD_NAME:/app/voices/en_US-libritts_r-medium.onnx -c init-openedai-speech-server
    kubectl cp ../../openedai-speech/voices/en_GB-northern_english_male-medium.onnx $OPENEDAI_SPEECH_SERVER_POD_NAME:/app/voices/en_GB-northern_english_male-medium.onnx -c init-openedai-speech-server
    kubectl cp ../../openedai-speech/voices/en_GB-northern_english_male-medium.onnx.json $OPENEDAI_SPEECH_SERVER_POD_NAME:/app/voices/en_GB-northern_english_male-medium.onnx.json -c init-openedai-speech-server
    kubectl cp ../../openedai-speech/voices/echo.wav $OPENEDAI_SPEECH_SERVER_POD_NAME:/app/voices/echo.wav -c init-openedai-speech-server
    kubectl cp ../../openedai-speech/voices/alloy.wav $OPENEDAI_SPEECH_SERVER_POD_NAME:/app/voices/alloy.wav -c init-openedai-speech-server
    kubectl cp ../../openedai-speech/voices/alloy-alt.wav $OPENEDAI_SPEECH_SERVER_POD_NAME:/app/voices/alloy-alt.wav -c init-openedai-speech-server
    kubectl cp ../../openedai-speech/voices/shimmer.wav $OPENEDAI_SPEECH_SERVER_POD_NAME:/app/voices/shimmer.wav -c init-openedai-speech-server
    kubectl cp ../../openedai-speech/config/config_files_will_go_here.txt $OPENEDAI_SPEECH_SERVER_POD_NAME:/app/config/config_files_will_go_here.txt -c init-openedai-speech-server
    kubectl cp ../../openedai-speech/config/pre_process_map.yaml $OPENEDAI_SPEECH_SERVER_POD_NAME:/app/config/pre_process_map.yaml -c init-openedai-speech-server
    kubectl cp ../../openedai-speech/config/voice_to_speaker.yaml $OPENEDAI_SPEECH_SERVER_POD_NAME:/app/config/voice_to_speaker.yaml -c init-openedai-speech-server
else
    echo "Skipping ai stack"
fi

kubectl apply -f "https://raw.githubusercontent.com/kubernetes/dashboard/v2.7.0/aio/deploy/recommended.yaml"
kubectl proxy &

helm template "$PROJECT_NAME" "."  --show-only "templates/dashboard-adminuser.yaml" > release/dashboard-adminuser.yaml
kubectl apply -f release/dashboard-adminuser.yaml -n kubernetes-dashboard

helm template "$PROJECT_NAME" "." --show-only "templates/dashboard-clusterrole.yaml" > release/dashboard-clusterrole.yaml
kubectl apply -f release/dashboard-clusterrole.yaml -n kubernetes-dashboard

helm template "$PROJECT_NAME" "." --show-only "templates/dashboard-secret.yaml" > release/dashboard-secret.yaml
kubectl apply -f release/dashboard-secret.yaml -n kubernetes-dashboard

echo 'Dashboard token:'
kubectl get secret admin-user -n kubernetes-dashboard -o jsonpath={".data.token"} | base64 -d

exit 0