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
helm install --name "consul-helm" ./
helm status consul-helm

#Register the stubDomain in core-dns
kubectl get svc consul-helm-dns -o jsonpath='{.spec.clusterIP}'
kubectl apply -f consul-dns.yaml
kubectl delete pod --namespace kube-system -l k8s-app=kube-dns

#Expose the UI
helm install stable/nginx-ingress --namespace default --set controller.replicaCount=1
kubectl get svc -l app=nginx-ingress
kubectl apply -f ui-ingress.yaml

#Add the vault certificates
kubectl create secret tls vault-tls --key privkey.pem --cert fullchain.pem

#Let's get the repo for the vault chart
helm repo add incubator http://storage.googleapis.com/kubernetes-charts-incubator
helm install --name v1 --values vault-values.yaml incubator/vault

#If there are issues with the helm chart, grab my copy
git clone https://github.com/ned1313/charts.git
helm install --name v1 --values PATH_TO_VALUES .

#And expose the Vault service publicly
kubectl apply -f vault-ingress.yaml
az network dns record-set a add-record --subscription SUB_NAME -g RESOURCE_GROUP -z ZONE_NAME -n vault-aks --ipv4-address LB_IP_ADDRESS