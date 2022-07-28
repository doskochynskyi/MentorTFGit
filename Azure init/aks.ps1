cd .\Downloads

az aks install-cli


set PATH=%PATH%;C:\Users\Ivan\.azure-kubectl

$env:path += 'C:\Users\Ivan\.azure-kubectl'

echo $env:path

az aks get-credentials --resource-group RGContainer --name AKSmnt

kubectl.exe get node

kubectl.exe describe pod

kubectl.exe get pod

kubectl.exe get deployment

kubectl.exe describe service

kubectl.exe get ns

kubectl.exe get ingress




#Install chocolatey. must be run as administrator
Set-ExecutionPolicy Bypass -Scope Process -Force; 
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; 
iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))

choco install kubernetes-helm -y --force

$NAMESPACE="ingress-basic"

kubectl create namespace $NAMESPACE


# ------------
# https://stacksimplify.com/azure-aks/azure-kubernetes-service-ingress-basics/
# Get the resource group name of the AKS cluster 
$nodeRGCont = az aks show --resource-group rgcontainer --name aksmnt --query nodeResourceGroup -o tsv

# TEMPLATE - Create a public IP address with the static allocation
$pipAKSIngress = az network public-ip create --resource-group $nodeRGCont --name PIPAKSForIngressNew --sku Standard --allocation-method static --query publicIp.ipAddress -o tsv

$pipAKSIngress = "23.97.137.194"

helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo add stable https://kubernetes-charts.storage.googleapis.com/
helm repo add stable https://charts.helm.sh/stable
helm repo update

#helm : W0724 14:59:19.815023   22212 warnings.go:70] spec.template.spec.nodeSelector[beta.kubernetes.io/os]: 
#deprecated since v1.14; use "kubernetes.io/os" instead
helm install ingress-nginx ingress-nginx/ingress-nginx `
    --namespace ingress-basic `
    --set controller.replicaCount=2 `
    --set controller.nodeSelector."kubernetes\.io/os"=linux `
    --set defaultBackend.nodeSelector."kubernetes\.io/os"=linux `
    --set controller.service.externalTrafficPolicy=Local `
    --set controller.service.loadBalancerIP=$pipAKSIngress




kubectl get service -l app.kubernetes.io/name=ingress-nginx --namespace ingress-basic

# List Pods
kubectl get pods -n ingress-basic
kubectl get all -n ingress-basic

cd 'C:\Users\Ivan\OneDrive - SoftServe, Inc\Documents\git\MentorTFGit\Azure init'

#-------------------

kubectl get service --namespace $NAMESPACE
kubectl get service --namespace $NAMESPACE


kubectl get ingress --namespace $NAMESPACE
kubectl get deployment --namespace $NAMESPACE
kubectl get service --namespace $NAMESPACE


$REGISTRY_NAME="acrmnt"
$SOURCE_REGISTRY="k8s.gcr.io"
$CONTROLLER_IMAGE="ingress-nginx/controller"
$CONTROLLER_TAG="v1.2.1"
$PATCH_IMAGE="ingress-nginx/kube-webhook-certgen"
$PATCH_TAG="v1.1.1"
$DEFAULTBACKEND_IMAGE="defaultbackend-amd64"
$DEFAULTBACKEND_TAG="1.5"

az acr import --name $REGISTRY_NAME --source "$SOURCE_REGISTRY/$CONTROLLER_IMAGE`:$CONTROLLER_TAG" --image "$CONTROLLER_IMAGE`:$CONTROLLER_TAG"
az acr import --name $REGISTRY_NAME --source $SOURCE_REGISTRY/$PATCH_IMAGE`:$PATCH_TAG --image $PATCH_IMAGE`:$PATCH_TAG
az acr import --name $REGISTRY_NAME --source $SOURCE_REGISTRY/$DEFAULTBACKEND_IMAGE`:$DEFAULTBACKEND_TAG --image $DEFAULTBACKEND_IMAGE`:$DEFAULTBACKEND_TAG


# Add the ingress-nginx repository
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx

# Set variable for ACR location to use for pulling images
$ACR_URL="acrmnt.azurecr.io"




cd 'C:\Users\Ivan\OneDrive - SoftServe, Inc\Documents\git\MentorTFGit\Azure init'
# Use Helm to deploy an NGINX ingress controller
helm install nginx-ingress ingress-nginx/ingress-nginx `
    --version "4.1.3" `
    --namespace "ingress-basic" `
    --create-namespace `
    --set controller.replicaCount=2 `
    --set controller.nodeSelector."kubernetes\.io/os"=linux `
    --set controller.image.registry=$ACR_URL `
    --set controller.image.image=$CONTROLLER_IMAGE `
    --set controller.image.tag=$CONTROLLER_TAG `
    --set controller.image.digest="" `
    --set controller.admissionWebhooks.patch.nodeSelector."kubernetes\.io/os"=linux `
    --set controller.service.annotations."service\.beta\.kubernetes\.io/azure-load-balancer-health-probe-request-path"=/healthz `
    --set controller.admissionWebhooks.patch.image.registry=$ACR_URL `
    --set controller.admissionWebhooks.patch.image.image=$PATCH_IMAGE `
    --set controller.admissionWebhooks.patch.image.tag=$PATCH_TAG `
    --set controller.admissionWebhooks.patch.image.digest="" `
    --set defaultBackend.nodeSelector."kubernetes\.io/os"=linux `
    --set defaultBackend.image.registry=$ACR_URL `
    --set defaultBackend.image.image=$DEFAULTBACKEND_IMAGE `
    --set defaultBackend.image.tag=$DEFAULTBACKEND_TAG `
    --set defaultBackend.image.digest="" `
    -f internal-ingress.yaml

    kubectl get pods --all-namespaces | Select-String ingress
    kubectl get service --all-namespaces | Select-String ingress

    kubectl get services --namespace ingress-basic -o wide -w nginx-ingress-ingress-nginx-controller

    helm list
    helm get all nginx-ingress
    helm get all release-name

    helm get manifest nginx-ingress
    helm get manifest release-name

#-----------------------------------------

helm list 
kubectl api-resources

kubectl get pods --all-namespaces
kubectl get deployment
kubectl get service --all-namespaces
kubectl get ingress --all-namespaces
kubectl delete ingress ingress-default-site

# delete all ingressclass 
kubectl get ingressclass --all-namespaces
kubectl delete ingressclass nginx --all-namespaces

#kubectl create -f .\default-ingressclass.yaml
kubectl create -f .\nodemnt-ingress.yaml

kubectl get -A ValidatingWebhookConfiguration
kubectl describe -A ValidatingWebhookConfiguration

kubectl delete validatingwebhookconfigurations nginx-ingress-ingress-nginx-admission
kubectl delete  nginx-ingress-ingress-nginx-controller-f7f697598

kubectl delete deployment nginx-ingress-ingress-nginx-controller


kubectl exec -it --namespace=default jsmnt-deployment-84d766b57b-6z2d5 -- bash 

kubectl create -f .\jsmnt-depl.yaml

kubectl describe deployment jsmnt-deployment

kubectl create -f .\jsmnt-service.yaml
kubectl create -f .\jsmnt-ingress.yaml

kubectl describe pod jsmnt-deployment-84d766b57b-6z2d5

kubectl describe service jsmnt-service
#kubectl delete service jsmnt-service 
kubectl describe ingress jsmnt-ingress

kubectl run -it --rm aks-ingress-test --image=mcr.microsoft.com/dotnet/runtime-deps:6.0 --namespace ingress-basic

kubectl exec -it --namespace=ingress-basic aks-ingress-test -- sh

kubectl exec --stdin --tty --namespace=ingress-basic aks-ingress-test -- /bin/bash

kubectl apply -f https://k8s.io/examples/application/shell-demo.yaml

kubectl exec --stdin --tty shell-demo -- /bin/bash

kubectl create -f .\jsmnt-depl-noexist.yaml

