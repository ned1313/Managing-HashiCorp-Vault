#Clone the helm chart for consul
git clone https://github.com/hashicorp/consul-helm.git
git checkout v0.1.0

#Get the kube config of the aks cluster
az login
az account set --subscription "sub_name"
az aks list
az aks get-credentials -n vault-rbac -g vault-aks

#Verify connection to aks
kubectl get nodes

#Scale to three nodes
az aks scale -n vault-rbac -g vault-aks -c 3

#Prepare helm for use
kubectl apply -f helm-rbac.yaml
helm init --service-account tiller

#Install the helm chart
helm install --dry-run ./
helm install --name "consul-helm" ./
helm status consul-helm

#Register the stubDomain in kube-dns
kubectl get svc consul-helm-dns -o jsonpath='{.spec.clusterIP}'
kubectl apply -f consul-dns.yaml

#Expose the UI
helm install stable/nginx-ingress --namespace default --set controller.replicaCount=1
kubectl get svc -l app=nginx-ingress
