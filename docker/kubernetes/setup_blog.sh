IFS=' ' read -ra STACK_ARRAY <<< "$STACKS"

if [[ "${STACK_ARRAY[@]}" =~ "blog" ]]; then
    # Copy files to the pod
    echo "Copying files blog..."
    NAMESPACE="default"
    TIMEOUT=300
    GHOST_DB_POD_NAME=$(kubectl --kubeconfig="$KUBECONFIG_PATH" get pods --no-headers=true | grep "^ghost-db" | awk '{print $1}' | head -n 1)
    if [[ -z "$GHOST_DB_POD_NAME" ]]; then
        echo "No pod found with label service=ghost-db"
    else
        start_time=$(date +%s)
        while true; do
            # Check if the pod is running
            status=$(kubectl --kubeconfig="$KUBECONFIG_PATH" get pod $GHOST_DB_POD_NAME -n $NAMESPACE -o jsonpath='{.status.initContainerStatuses[*].state}')
            status_key=$(echo "$status" | sed 's/^{"\([^"]*\)":.*/\1/')
            if [ "$status_key" = "running" ]; then
                echo "Pod $GHOST_DB_POD_NAME is running"
                break
            else
                current_time=$(date +%s)
                elapsed_time=$((current_time - start_time))
                
                if [ $elapsed_time -ge $TIMEOUT ]; then
                    echo "Timeout: Pod $GHOST_DB_POD_NAME did not run within $TIMEOUT seconds"
                    break
                fi
                
                echo "Waiting for pod $GHOST_DB_POD_NAME to be running..."
                sleep 5 # Wait for 5 seconds before checking again
            fi
        done
    fi
else
    echo "Skipping blog stack"
fi