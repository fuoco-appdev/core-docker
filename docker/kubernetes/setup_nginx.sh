IFS=' ' read -ra STACK_ARRAY <<< "$STACKS"
NGINX_POD_NAME=$(kubectl --kubeconfig="$KUBECONFIG_PATH" get pods --no-headers=true | grep "^nginx.*Init" | awk '{print $1}' | head -n 1)
NAMESPACE="default"
TIMEOUT=60

if [[ -z "$NGINX_POD_NAME" ]]; then
    echo "No pod found with label service=nginx"
else
    # Copy files to the pod
    echo "Copying files to nginx..."
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
        envsubst < ../volumes/nginx/conf.d/http/core.conf.template > ../volumes/nginx/conf.d/http/core.conf
        kubectl --kubeconfig="$KUBECONFIG_PATH" cp ../volumes/nginx/conf.d/http/core.conf $NGINX_POD_NAME:/tmp/etc/nginx/conf.d/http/core.conf -c init-nginx
        export NGINX_CORE_HTTP_CONFIG="include /etc/nginx/conf.d/http/core.conf;"

        envsubst < ../volumes/nginx/conf.d/stream/core.conf.template > ../volumes/nginx/conf.d/stream/core.conf
        kubectl --kubeconfig="$KUBECONFIG_PATH" cp ../volumes/nginx/conf.d/stream/core.conf $NGINX_POD_NAME:/tmp/etc/nginx/conf.d/stream/core.conf -c init-nginx
        export NGINX_CORE_STREAM_CONFIG="include /etc/nginx/conf.d/stream/core.conf;"
    else
        echo "Skipping nginx core config"
    fi

    if [[ "${STACK_ARRAY[@]}" =~ "ecommerce" ]]; then
        envsubst < ../volumes/nginx/conf.d/http/ecommerce.conf.template > ../volumes/nginx/conf.d/http/ecommerce.conf
        kubectl --kubeconfig="$KUBECONFIG_PATH" cp ../volumes/nginx/conf.d/http/ecommerce.conf $NGINX_POD_NAME:/tmp/etc/nginx/conf.d/http/ecommerce.conf -c init-nginx
        export NGINX_ECOMMERCE_HTTP_CONFIG="include /etc/nginx/conf.d/http/ecommerce.conf;"
    else
        echo "Skipping nginx ecommerce config"
    fi

    if [[ "${STACK_ARRAY[@]}" =~ "ai" ]]; then
        envsubst < ../volumes/nginx/conf.d/http/ai.conf.template > ../volumes/nginx/conf.d/http/ai.conf
        kubectl --kubeconfig="$KUBECONFIG_PATH" cp ../volumes/nginx/conf.d/http/ai.conf $NGINX_POD_NAME:/tmp/etc/nginx/conf.d/http/ai.conf -c init-nginx
        export NGINX_AI_HTTP_CONFIG="include /etc/nginx/conf.d/http/ai.conf;"
    else
        echo "Skipping nginx ai config"
    fi

    kubectl --kubeconfig="$KUBECONFIG_PATH" cp ../volumes/nginx/.htpasswd $NGINX_POD_NAME:/tmp/etc/nginx/.htpasswd -c init-nginx
    kubectl --kubeconfig="$KUBECONFIG_PATH" cp ../volumes/nginx/domain.pass $NGINX_POD_NAME:/tmp/etc/ssl/domain.pass -c init-nginx
    kubectl --kubeconfig="$KUBECONFIG_PATH" cp --no-preserve ../volumes/nginx/domain.crt $NGINX_POD_NAME:/tmp/etc/ssl/domain.crt -c init-nginx
    kubectl --kubeconfig="$KUBECONFIG_PATH" cp --no-preserve ../volumes/nginx/domain.key $NGINX_POD_NAME:/tmp/etc/ssl/domain.key -c init-nginx
    envsubst < ../volumes/nginx/nginx.conf.template > ../volumes/nginx/nginx.conf
    kubectl --kubeconfig="$KUBECONFIG_PATH" cp ../volumes/nginx/nginx.conf $NGINX_POD_NAME:/tmp/etc/nginx/nginx.conf -c init-nginx
fi