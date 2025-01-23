#!/bin/bash

# Check if the environment file is provided
if [ -z "$1" ]; then
    echo "Usage: $0 <env_file>"
    exit 1
fi

# Load environment variables from the file
set -a
source "$1"
set +a

# Function to initialize or check Swarm
init_or_check_swarm() {
    if ! docker info | grep -q "Swarm: active"; then
        docker swarm init
        echo "Swarm initialized."
        # Update MANAGER_TOKEN for workers
        MANAGER_TOKEN=$(docker swarm join-token -q worker)
        MANAGER_IP=$(docker info | grep -A 1 "Node Address" | tail -n1 | awk '{print $2}')
    else
        echo "Swarm is already initialized."
    fi
}

# Function to join workers to the swarm
join_workers() {
    local nodes=($WORKER_NODES)
    for node in "${nodes[@]}"; do
        echo "Attempting to join $node to the swarm..."
        ssh $node "docker swarm join --token $MANAGER_TOKEN $MANAGER_IP:2377" || echo "Failed to join $node to swarm"
    done
}

# Function to manage node labels
manage_labels() {
    local labels=($NODE_LABELS)
    for label_entry in "${labels[@]}"; do
        IFS=':' read -r node label_string <<< "$label_entry"
        IFS=',' read -ra label_array <<< "$label_string"
        IFS='@' read -r user ip <<< "$node"

        # Apply labels to the node
        for label in "${label_array[@]}"; do
            key=${label%=*}
            value=${label#*=}

            if [ "$ip" != "localhost" ]; then
                ssh $node "docker node update --label-add $key=$value $(docker info -f '{{.Swarm.NodeID}}')" || echo "Failed to add label $key=$value to $node"
            else
                docker node update --label-add $key=$value $(docker info -f '{{.Swarm.NodeID}}') || echo "Failed to add label $key=$value to $node"
            fi
        done
    done
}

# Initialize or check Swarm
init_or_check_swarm

# If this is the manager node, join workers and apply labels
if docker info | grep -q "Swarm: active"; then
    join_workers
    manage_labels
fi

# Deploy services based on STACKS
IFS=' ' read -ra STACK_ARRAY <<< "$STACKS"
for stack in "${STACK_ARRAY[@]}"; do
    stack_file="docker-stack.$stack.yml"
    if [ -f "$stack_file" ]; then
        echo "Deploying $stack stack..."
        docker stack deploy -c "$stack_file" "$stack" || echo "Failed to deploy $stack stack"
    else
        echo "Compose file for $stack stack ($stack_file) does not exist."
    fi
done

echo "Deployment process completed."