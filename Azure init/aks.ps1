cd .\Downloads

az aks install-cli


set PATH=%PATH%;C:\Users\Ivan\.azure-kubectl

$env:path += 'C:\Users\Ivan\.azure-kubectl'

echo $env:path

az aks get-credentials --resource-group RGContainer --name AKSmnt


################################################
########    Install helm       #################
################################################

#Install chocolatey. must be run as administrator
Set-ExecutionPolicy Bypass -Scope Process -Force; 
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; 
iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))

choco install kubernetes-helm -y --force

$NAMESPACE="ingress-basic"

kubectl create namespace $NAMESPACE


################################################
######## Install nginx ingress #################
################################################

# https://stacksimplify.com/azure-aks/azure-kubernetes-service-ingress-basics/
# Get the resource group name of the AKS cluster 
$nodeRGCont = az aks show --resource-group rgcontainer --name aksmnt --query nodeResourceGroup -o tsv

# TEMPLATE - Create a public IP address with the static allocation
#$pipAKSIngress = az network public-ip create --resource-group $nodeRGCont --name PIPAKSForIngressNew --sku Standard --allocation-method static --query publicIp.ipAddress -o tsv

# get from mc_ resource group
$pipAKSIngress = "20.31.49.188"

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

#-------------------

kubectl get service --namespace $NAMESPACE
kubectl get service --namespace $NAMESPACE


kubectl get ingress --namespace $NAMESPACE
kubectl get deployment --namespace $NAMESPACE
kubectl get service --namespace $NAMESPACE

# MS guide to install nginx ingress
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
# https://github.com/doskochynskyi/MentorTFGit.git

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
kubectl get deployment --all-namespaces
kubectl get service --all-namespaces
kubectl get ingress --all-namespaces
kubectl delete ingress ingress-default-site
 

# delete all ingressclass 
kubectl get ingressclass --all-namespaces
kubectl describe ingressclass --all-namespaces
kubectl delete ingressclass nginx --all-namespaces

#kubectl create -f .\default-ingressclass.yaml
kubectl create -f .\nodemnt-ingress.yaml

kubectl get -A ValidatingWebhookConfiguration
kubectl describe -A ValidatingWebhookConfiguration

kubectl delete validatingwebhookconfigurations nginx-ingress-ingress-nginx-admission
kubectl delete  nginx-ingress-ingress-nginx-controller-f7f697598

kubectl delete deployment mntdevga-app --namespace dev
kubectl delete pod mntdevga-app-5d4f48f8f-2wlr7 --namespace dev
kubectl delete service  mntdevga-app --namespace dev
kubectl delete ingress  mntdevga-app --namespace dev


################################################
########       Deploy app manually      ########
################################################

cd 'C:\Users\Ivan\OneDrive - SoftServe, Inc\Documents\git\MentorTFGit\Azure init\ManualDeployApp'
# https://github.com/doskochynskyi/MentorTFGit.git

kubectl create -f .\jsmnt-depl.yaml
kubectl create -f .\jsmnt-service.yaml
kubectl create -f .\jsmnt-ingress.yaml

kubectl delete deployment jsmnt-deployment
kubectl delete pod jsmnt-deployment-84d766b57b-6rthd
kubectl describe deployment jsmnt-deployment
kubectl describe pod mntdevga-app-68885d6cd4-4k255
kubectl describe service jsmnt-service
#kubectl delete service jsmnt-service 
kubectl describe ingress jsmnt-ingress
#kubectl delete ingress jsmnt-ingress

kubectl run -it --rm aks-ingress-test --image=mcr.microsoft.com/dotnet/runtime-deps:6.0 --namespace ingress-basic

kubectl exec -it mntdevga-app-88b4dc49b-288ls --namespace dev -- /bin/bash
kubectl exec --stdin --tty mntdevga-app-88b4dc49b-288ls --namespace dev -- /bin/bash

kubectl apply -f https://k8s.io/examples/application/shell-demo.yaml

kubectl create -f .\jsmnt-depl-noexist.yaml

mkdir chart
cd .\chart

helm create mntapp


################################################
########       Deploy app by helm       ########
################################################

cd 'C:\Users\Ivan\OneDrive - SoftServe, Inc\Documents\git\MentorTFGit\Azure init'
# https://github.com/doskochynskyi/MentorTFGit.git

helm install mntdev --namespace dev --create-namespace --values values-dev.yaml  .\chart\app
helm list -A
helm uninstall mntdev --namespace dev
kubectl describe pod  mntdevga-app-5b8ddf9b5c-85zbr --namespace dev
kubectl describe service mntdevga-app --namespace dev
kubectl describe ingress mntdevga-app --namespace dev
kubectl logs mntdev-app --namespace dev
kubectl logs ingress-nginx-controller-55dcf56b68-pdz8n --namespace ingress-basic
kubectl logs mntdevga-app-88b4dc49b-288ls --namespace dev


#########################################################
########       Deploy app by github actions      ########
#########################################################

https://github.com/doskochynskyi/MentorAKS/


#############################################################################
#########    Generate certificate manually and put it to secret      ########     
#############################################################################

# https://kubernetes.io/docs/concepts/services-networking/ingress/#tls
 

New-SelfSignedCertificate -DnsName "mntjsdev.com" -CertStoreLocation "cert:\LocalMachine\My"

openssl pkcs12 -in mntjsdev.pfx -nocerts -out p.key -nodes -passin pass:123
openssl pkcs12 -in mntjsdev.pfx -nokeys -out mntjsdev.crt -nodes -passin pass:123

<#
apiVersion: v1
kind: Secret
metadata:
  name: testsecret-tls
  namespace: default
data:
  tls.crt: base64 encoded cert
  tls.key: base64 encoded key
type: kubernetes.io/tls
#>

kubectl create secret tls dev-tls-secret `
  --cert=.\mntjsdev.crt `
  --key=.\mntjsdev.key

kubectl get secret dev-tls-secret
kubectl describe secret


cd 'C:\Users\Ivan\OneDrive - SoftServe, Inc\Documents\git\MentorTFGit\Azure init\ManualDeployApp'
# https://github.com/doskochynskyi/MentorTFGit.git
kubectl create -f .\jsmnt-depl.yaml
kubectl create -f .\jsmnt-service.yaml
kubectl create -f .\jsmnt-ingress-k8s-secret.yaml


#######################################################
########    MS guide to install cert-manager   ########
#######################################################

<#
$RegistryName = "<REGISTRY_NAME>"
$ResourceGroup = (Get-AzContainerRegistry | Where-Object {$_.name -eq $RegistryName} ).ResourceGroupName
$CertManagerRegistry = "quay.io"
$CertManagerTag = "v1.8.0"
$CertManagerImageController = "jetstack/cert-manager-controller"
$CertManagerImageWebhook = "jetstack/cert-manager-webhook"
$CertManagerImageCaInjector = "jetstack/cert-manager-cainjector"

Import-AzContainerRegistryImage -ResourceGroupName $ResourceGroup -RegistryName $RegistryName -SourceRegistryUri $CertManagerRegistry -SourceImage "${CertManagerImageController}:${CertManagerTag}"
Import-AzContainerRegistryImage -ResourceGroupName $ResourceGroup -RegistryName $RegistryName -SourceRegistryUri $CertManagerRegistry -SourceImage "${CertManagerImageWebhook}:${CertManagerTag}"
Import-AzContainerRegistryImage -ResourceGroupName $ResourceGroup -RegistryName $RegistryName -SourceRegistryUri $CertManagerRegistry -SourceImage "${CertManagerImageCaInjector}:${CertManagerTag}"


helm install cert-manager jetstack/cert-manager `
  --namespace ingress-basic `
  --version $CertManagerTag `
  --set installCRDs=true `
  --set nodeSelector."kubernetes\.io/os"=linux `
  --set image.repository="${AcrUrl}/${CertManagerImageController}" `
  --set image.tag=$CertManagerTag `
  --set webhook.image.repository="${AcrUrl}/${CertManagerImageWebhook}" `
  --set webhook.image.tag=$CertManagerTag `
  --set cainjector.image.repository="${AcrUrl}/${CertManagerImageCaInjector}" `
  --set cainjector.image.tag=$CertManagerTag
#>


###########################################################################
#######    Genarate certificate by cert-manager.io automatically    #######
###########################################################################

# https://cert-manager.io/docs/configuration/acme/#adding-multiple-solver-types
# https://cert-manager.io/docs/tutorials/acme/nginx-ingress/#certificates
# https://cert-manager.io/docs/installation/helm/#3-install-customresourcedefinitions

helm repo add jetstack https://charts.jetstack.io

helm repo update

helm install `
  cert-manager jetstack/cert-manager `
  --namespace ingress-basic `
  --version v1.9.1 `
  --set installCRDs=true 

kubectl get pod --namespace ingress-basic
kubectl get pod --namespace dev
kubectl get svc --namespace dev


kubectl create -f .\jsmnt-issuer-certmanager-dev.yaml --namespace dev
kubectl create -f .\jsmnt-ingress-certmanager-dev.yaml

kubectl describe ingress jsmnt-ingress
kubectl get certificate  --all-namespaces
kubectl describe certificate  jsmnt-dev-tls --namespace dev
kubectl describe secret jsmnt-dev-tls
kubectl describe issuer letsencrypt-dev --namespace dev
#kubectl delete ingress jsmnt-ingress
kubectl get issuer --namespace dev
kubectl get secret --all-namespaces 
kubectl get secret --namespace dev
kubectl describe secret letsencrypt-dev --namespace dev
kubectl describe secret jsmnt-dev-tls --namespace dev
kubectl delete issuer letsencrypt-dev
kubectl delete secret jsmnt-dev-tls


helm list --all-namespaces
helm show chart cert-manager  --all-namespaces
helm template .\test\charts\app
helm verify .\test\charts\app
kubectl get all -n dev


#########################################################
########       Monitoring by Azure Monitor       ########
#########################################################

$laAKSid = az resource list --resource-type Microsoft.OperationalInsights/workspaces  --query '[].id' -o tsv
az aks enable-addons -a monitoring -n aksmnt -g rgcontainer --workspace-resource-id $laAKSid

kubectl get ds omsagent --namespace=kube-system

kubectl get configmap --all-namespaces

kubectl describe configmap coredns --namespace kube-system


#########################################################
#######    Monitoring by Prometheus + Grafana     #######
#########################################################

helm repo add stable https://charts.helm.sh/stable

helm repo add prometheus-community https://prometheus-community.github.io/helm-charts

helm search repo prometheus-community

kubectl create namespace prometheus

helm install stable prometheus-community/kube-prometheus-stack -n prometheus

kubectl get -n monitoring crds
kubectl get -n prometheus crds
kubectl get ns

kubectl get pods -n prometheus
kubectl get all -n prometheus

kubectl get svc -n prometheus
kubectl get ingress -n prometheus

kubectl describe pods prometheus-stable-kube-prometheus-sta-prometheus-0 -n prometheus
kubectl logs prometheus-stable-kube-prometheus-sta-prometheus-0 -n prometheus
kubectl describe svc stable-kube-prometheus-sta-prometheus -n prometheus
kubectl get pods -l app=hostnames
kubectl logs stable-kube-prometheus-sta-prometheus -n prometheus
kubectl get ingress prom-ingress -n prometheus
kubectl describe ingress prom-ingress -n prometheus
kubectl delete ingress prom-ingress -n prometheus

kubectl describe pods stable-grafana-6f8bccdd57-59cxl -n prometheus
kubectl describe svc stable-grafana -n prometheus
kubectl get ingress grafana-ingress -n prometheus
kubectl describe ingress grafana-ingress -n prometheus

kubectl edit svc stable-kube-prometheus-sta-prometheus -n prometheus

kubectl edit svc stable-grafana -n prometheus

kubectl create -f .\prometheus-ingress-certmanager-tls.yaml --namespace prometheus
kubectl create -f .\grafana-ingress-certmanager-tls.yaml --namespace prometheus

kubectl logs ingress-nginx-controller-55dcf56b68-6kxb7 -n ingress-basic
kubectl logs ingress-nginx-controller-55dcf56b68-prlxr -n ingress-basic

$grPod = "stable-grafana-ddb6b668d-d2dlk"
kubectl logs --follow $grPod -c grafana --namespace prometheus
kubectl logs $grPod -c grafana --namespace prometheus
kubectl logs --tail=10 $grPod -c grafana --namespace prometheus

kubectl get deploy --all-namespaces
kubectl edit deploy stable-grafana --namespace prometheus
kubectl describe pvc stable-grafana --namespace prometheus

kubectl get pvc --namespace prometheus
kubectl get pod -A
kubectl get all -A

