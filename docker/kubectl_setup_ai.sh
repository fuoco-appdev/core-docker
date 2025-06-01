IFS=' ' read -ra STACK_ARRAY <<< "$STACKS"

if [[ "${STACK_ARRAY[@]}" =~ "ai" ]]; then
    # Copy files to the pod
    echo "Copying files ai..."
    NAMESPACE="default"
    TIMEOUT=300
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

        kubectl --kubeconfig="$KUBECONFIG_PATH" cp ../openedai-speech/voices/onyx.wav $OPENEDAI_SPEECH_SERVER_POD_NAME:/app/voices/onyx.wav -c init-openedai-speech-server
        kubectl --kubeconfig="$KUBECONFIG_PATH" cp ../openedai-speech/voices/nova.wav $OPENEDAI_SPEECH_SERVER_POD_NAME:/app/voices/nova.wav -c init-openedai-speech-server
        kubectl --kubeconfig="$KUBECONFIG_PATH" cp ../openedai-speech/voices/fable.wav $OPENEDAI_SPEECH_SERVER_POD_NAME:/app/voices/fable.wav -c init-openedai-speech-server
        kubectl --kubeconfig="$KUBECONFIG_PATH" cp ../openedai-speech/voices/en_US-libritts_r-medium.onnx $OPENEDAI_SPEECH_SERVER_POD_NAME:/app/voices/en_US-libritts_r-medium.onnx -c init-openedai-speech-server
        kubectl --kubeconfig="$KUBECONFIG_PATH" cp ../openedai-speech/voices/en_GB-northern_english_male-medium.onnx $OPENEDAI_SPEECH_SERVER_POD_NAME:/app/voices/en_GB-northern_english_male-medium.onnx -c init-openedai-speech-server
        kubectl --kubeconfig="$KUBECONFIG_PATH" cp ../openedai-speech/voices/en_GB-northern_english_male-medium.onnx.json $OPENEDAI_SPEECH_SERVER_POD_NAME:/app/voices/en_GB-northern_english_male-medium.onnx.json -c init-openedai-speech-server
        kubectl --kubeconfig="$KUBECONFIG_PATH" cp ../openedai-speech/voices/echo.wav $OPENEDAI_SPEECH_SERVER_POD_NAME:/app/voices/echo.wav -c init-openedai-speech-server
        kubectl --kubeconfig="$KUBECONFIG_PATH" cp ../openedai-speech/voices/alloy.wav $OPENEDAI_SPEECH_SERVER_POD_NAME:/app/voices/alloy.wav -c init-openedai-speech-server
        kubectl --kubeconfig="$KUBECONFIG_PATH" cp ../openedai-speech/voices/alloy-alt.wav $OPENEDAI_SPEECH_SERVER_POD_NAME:/app/voices/alloy-alt.wav -c init-openedai-speech-server
        kubectl --kubeconfig="$KUBECONFIG_PATH" cp ../openedai-speech/voices/shimmer.wav $OPENEDAI_SPEECH_SERVER_POD_NAME:/app/voices/shimmer.wav -c init-openedai-speech-server
        kubectl --kubeconfig="$KUBECONFIG_PATH" cp ../openedai-speech/config/config_files_will_go_here.txt $OPENEDAI_SPEECH_SERVER_POD_NAME:/app/config/config_files_will_go_here.txt -c init-openedai-speech-server
        kubectl --kubeconfig="$KUBECONFIG_PATH" cp ../openedai-speech/config/pre_process_map.yaml $OPENEDAI_SPEECH_SERVER_POD_NAME:/app/config/pre_process_map.yaml -c init-openedai-speech-server
        kubectl --kubeconfig="$KUBECONFIG_PATH" cp ../openedai-speech/config/voice_to_speaker.yaml $OPENEDAI_SPEECH_SERVER_POD_NAME:/app/config/voice_to_speaker.yaml -c init-openedai-speech-server
    fi
else
    echo "Skipping ai stack"
fi