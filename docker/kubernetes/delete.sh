kubectl delete -f .

kubectl delete deployments --all --all-namespaces
kubectl delete pods --all --all-namespaces
kubectl delete services --all --all-namespaces
kubectl delete configmaps --all --all-namespaces
kubectl delete secrets --all --all-namespaces
kubectl delete replicasets --all --all-namespaces
kubectl delete statefulsets --all --all-namespaces
kubectl delete persistentvolumeclaims --all --all-namespaces
kubectl delete jobs --all --all-namespaces
kubectl delete cronjobs --all --all-namespaces
kubectl delete daemonsets --all --all-namespaces
kubectl delete ingress --all --all-namespaces
kubectl delete networkpolicies --all --all-namespaces