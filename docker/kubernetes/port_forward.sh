STUDIO_DEPLOYMENT_NAME=$(kubectl get deployments --no-headers=true | grep "^studio" | awk '{print $1}' | head -n 1)
MEDUSA_SERVER_DEPLOYMENT_NAME=$(kubectl get deployments --no-headers=true | grep "^medusa-server" | awk '{print $1}' | head -n 1)
DASHBOARD_DEPLOYMENT_NAME=$(kubectl get deployments --no-headers=true | grep "^dashboard" | awk '{print $1}' | head -n 1)
kubectl port-forward deployment/$STUDIO_DEPLOYMENT_NAME 3000:3000 &
kubectl port-forward deployment/$MEDUSA_SERVER_DEPLOYMENT_NAME 9010:9010 &
kubectl port-forward deployment/$DASHBOARD_DEPLOYMENT_NAME 8001:8001 &