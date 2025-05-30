STUDIO_DEPLOYMENT_NAME=$(kubectl get deployments --no-headers=true | grep "^studio" | awk '{print $1}' | head -n 1)
ANALYTICS_DEPLOYMENT_NAME=$(kubectl get deployments --no-headers=true | grep "^analytics" | awk '{print $1}' | head -n 1)
MEDUSA_SERVER_DEPLOYMENT_NAME=$(kubectl get deployments --no-headers=true | grep "^medusa-server" | awk '{print $1}' | head -n 1)
DASHBOARD_DEPLOYMENT_NAME=$(kubectl get deployments --no-headers=true | grep "^dashboard" | awk '{print $1}' | head -n 1)
KONG_DEPLOYMENT_NAME=$(kubectl get deployments --no-headers=true | grep "^kong" | awk '{print $1}' | head -n 1)
DB_DEPLOYMENT_NAME=$(kubectl get deployments --no-headers=true | grep "^db" | awk '{print $1}' | head -n 1)
kubectl port-forward deployment/$STUDIO_DEPLOYMENT_NAME 3000:3000 &
kubectl port-forward deployment/$ANALYTICS_DEPLOYMENT_NAME 4000:4000 &
kubectl port-forward deployment/$MEDUSA_SERVER_DEPLOYMENT_NAME 9010:9010 &
kubectl port-forward deployment/$DASHBOARD_DEPLOYMENT_NAME 8001:8001 &
kubectl port-forward deployment/$KONG_DEPLOYMENT_NAME 8000:8000 &
kubectl port-forward deployment/$DB_DEPLOYMENT_NAME 5432:5432 &