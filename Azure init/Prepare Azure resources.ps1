
# Create a virtual network.
az network vnet create `
--resource-group RGContainer `
--name VNETContainer `
--address-prefixes 192.168.125.0/24 `
--subnet-name snContainer `
--subnet-prefixes 192.168.125.0/24;

# Create a virtual network.
az network vnet create `
--resource-group RGManagement `
--name VNETManagement `
--address-prefixes 192.168.200.0/24 `
--subnet-name snManagement `
--subnet-prefixes 192.168.200.0/25;

# Create a public IP address.
az network public-ip create `
--resource-group RGManagement `
--name PIPVMadmin `
--sku Standard `
--dns-name jenkinsmentor;


# Create a network security group.
az network nsg create `
--resource-group RGManagement `
--name VMadminNSG;

az network nsg rule create -g RGManagement --nsg-name VMadminNSG -n RDPAllow --priority 1100 `
    --source-address-prefixes '*' `
    --destination-address-prefixes '*' --destination-port-ranges 3389 --access Allow `
    --protocol Tcp --description "Allow connect to RDP."


# Create a virtual network card and associate with a public IP address and NSG.
az network nic create `
--resource-group RGManagement `
--name NicVMadmin `
--vnet-name VNETManagement `
--subnet snManagement `
--network-security-group VMadminNSG `
--public-ip-address PIPVMadmin;

#az vm image list -f Ubuntu --all --location westeurope --all -otable;
#az vm image list -f "Windows-10" --location westeurope --all -otable
#az account list-locations
az vm create `
  --resource-group "RGManagement" `
  --name "VMadmin" `
  --image "MicrosoftWindowsDesktop:Windows-10:win10-21h2-pro:19044.1706.220505" `
  --admin-username "dizen" `
  --admin-password "Install_mnt1" `
  --location westeurope `
  --size Standard_D2as_v5 `
   --nics NicVMadmin

az network public-ip create `
--resource-group RGManagement `
--name PIPVMJnkUbuntu;

az network nic create `
--resource-group RGManagement `
--name NicVMJnkUbuntu `
--vnet-name VNETManagement `
--subnet snManagement `
--network-security-group NSGManagement `
--public-ip-address PIPVMJnkUbuntu;

az network nsg create `
--resource-group RGManagement `
--name VMJnkUbuntuNSG;


ubuntu-20-04-lts
nodejs-10-with-ubuntu-20-04-lts
az vm create `
  --resource-group "RGManagement" `
  --name "VMJnkUbuntu" `
  --image "ubuntu-20-04-lts" `
  --admin-username "dizen" `
  --admin-password "Install_mnt1" `
  --location westeurope `
  --size Standard_D2as_v5

ubuntu-20-04-lts

#https://docs.microsoft.com/en-us/azure/container-registry/container-registry-authentication-managed-identity
#https://docs.microsoft.com/en-us/azure/container-instances/container-instances-github-action
#az vm identity assign --resource-group myResourceGroup --name myDockerVM --identities $userID




az provider list --query "[?namespace=='Microsoft.ContainerInstance']" --output table

az provider register --namespace Microsoft.ContainerInstance



#az aks create --resource-group  --name AKSmentor --location westeurope --attach-acr MyHelmACR --generate-ssh-keys

#az aks create -g RGContainer -n AKSmentor --enable-managed-identity --node-count 1 --generate-ssh-keys

az ad sp create-for-rbac --name "spAKS" --role contributor --scopes /subscriptions/$subscID/resourceGroups/RGContainer --sdk-auth

spAKS json:
{
  "clientId": "7934ebf9-b8fd-4136-906b-6c5aad182291",
  "clientSecret": "lWYPbf6~D5wYs9-htn_0UPC~Nfb24~somS",
  "subscriptionId": "2352ce5d-34de-4b16-a1c2-a3a737e8e182",
  "tenantId": "87bbb889-b90a-4038-b351-206df81b3396",
  "activeDirectoryEndpointUrl": "https://login.microsoftonline.com",
  "resourceManagerEndpointUrl": "https://management.azure.com/",
  "activeDirectoryGraphResourceId": "https://graph.windows.net/",
  "sqlManagementEndpointUrl": "https://management.core.windows.net:8443/",
  "galleryEndpointUrl": "https://gallery.azure.com/",
  "managementEndpointUrl": "https://management.core.windows.net/"
}




$resourceID=$(az acr show --resource-group RGContainer --name acrmentor --query id --output tsv)
$spID=$(az vm show --resource-group RGManagement --name VMadmin --query identity.principalId --out tsv)

az role assignment create --assignee $spID --scope $resourceID --role acrpush
az role assignment create --assignee $spID --scope $resourceID --role acrpull

# Before creating KeyVault assign service endpoint Azure KeyVault to subnet snManagement
az keyvault create --location westeurope --name KVMntAdmin --resource-group RGManagement --network-acls-vnets VNETManagement/snManagement

# Create a secret for connect to github
$VMAdminIdentity = az vm identity show --name VMAdmin --resource-group RGManagement  | ConvertFrom-Json

az keyvault set-policy `
    --secret-permissions get list `
    --name KVMntAdmin `
    --object-id $VMAdminIdentity.principalId

az ad sp create-for-rbac --name http://jenkinskeyaccess
az keyvault set-policy `
    --secret-permissions get list `
    --name KVMntAdmin `
    --object-id f4ebc9e4-5872-4d6f-97b8-f26756a5833f

az network nsg rule create -g RGManagement --nsg-name VMadminNSG -n JenkinsAllow --priority 1100 `
    --source-address-prefixes '*' `
    --destination-address-prefixes '*' --destination-port-ranges 8080 --access Allow `
    --protocol Tcp --description "Allow connect to Jenkins 8080."

az network nsg rule create -g RGManagement --nsg-name VMadminNSG -n JenkinsAgentAllow --priority 1200 `
    --source-address-prefixes '*' `
    --destination-address-prefixes '*' --destination-port-ranges 888 --access Allow `
    --protocol Tcp --description "Allow connect to Jenkins 888."

$RGContainerID=$(az group show --resource-group RGContainer --query id --output tsv)
$vmAdminID=$(az vm show --resource-group RGManagement --name VMadmin --query identity.principalId --out tsv)

az role assignment create --assignee $vmAdminID --scope $RGContainerID --role reader

#az container create --resource-group RGManagement --name nodemnt --image acrmentor.azurecr.io/node-docker-mnt:1.0.0 --acr-identity eea7fecd-81d4-4cc8-9943-d4769d3d46c8 --dns-name-label nodemnt --ports 80


#Deploy to Azure Container Instances from Azure Container Registry using a service principal
$RES_GROUP="RGContainer" # Resource Group name
$ACR_NAME="acrmentor"       # Azure Container Registry registry name
$AKV_NAME="KVContainer"       # Azure Key Vault vault name

az keyvault create -g $RES_GROUP -n $AKV_NAME

az ad sp create-for-rbac `
  --name http://$ACR_NAME-pull `
  --scopes $(az acr show --name $ACR_NAME --query id --output tsv) `
  --role acrpull

######## copy appid and password from output #######
$SP_ID="67fce907-0cf1-44f6-a478-57d05cc21df0"

az keyvault secret set `
  --vault-name $AKV_NAME `
  --name "$ACR_NAME-pull-pwd" `
  --value "s.xRtdIUEG3aKa-H.WeXZOvSusLk6ILKjj"


az keyvault secret set `
    --vault-name $AKV_NAME `
    --name $ACR_NAME-pull-usr `
    --value $(az ad sp show --id $SP_ID --query appId --output tsv)

$ACR_LOGIN_SERVER=$(az acr show --name $ACR_NAME --resource-group $RES_GROUP --query "loginServer" --output tsv)

az network vnet create `
--resource-group $RES_GROUP `
--name VNETContainer `
--address-prefixes 192.168.150.0/24 `
--subnet-name snContainer `
--subnet-prefixes 192.168.150.0/25;

az container create `
    --name node-docker-mnt `
    --resource-group $RES_GROUP `
    --image $ACR_LOGIN_SERVER/node-docker-mnt:1.0.0 `
    --cpu 1 `
    --memory 1 `
    --ports 3000 `
    --vnet VNETContainer `
    --subnet snContainer `
    --registry-login-server $ACR_LOGIN_SERVER `
    --registry-username $(az keyvault secret show --vault-name $AKV_NAME -n $ACR_NAME-pull-usr --query value -o tsv) `
    --registry-password $(az keyvault secret show --vault-name $AKV_NAME -n $ACR_NAME-pull-pwd --query value -o tsv) `
    --dns-name-label "nodedockermnt"`
    --query ipAddress.fqdn

az network vnet create `
--resource-group RGContainer `
--name VNETNginx `
--address-prefixes 192.168.126.0/24 `
--subnet-name snNginx `
--subnet-prefixes 192.168.126.0/24;

az container create `
    --resource-group RGcontainer `
    --name nginxtest `
    --image acrmnt.azurecr.io/nginxtest:v1 `
    --registry-login-server acrmnt.azurecr.io `
    --registry-username nginx@ivdo7788gmail.onmicrosoft.com `
    --registry-password 'Install_mnt1' `
    --vnet aci-vnet `
    --vnet-address-prefix 10.0.0.0/16 `
    --subnet aci-subnet `
    --subnet-address-prefix 10.0.0.0/24 `
    --port 80



        --dns-name-label nginxtest  `

        az container show --name nginxtest `
  --resource-group RGcontainer `
  --query ipAddress.ip --output tsv


region {
################################################
### expose container thr Azure Firewall NAT ####


$resourceGroup="RGContainer"

az container list --output table
az container show --name nginxtest --resource-group $resourceGroup | Select-String "network"

    az container create `
    --resource-group RGcontainer `
    --name nginxtest `
    --image acrmnt.azurecr.io/nginxtest:v1 `
    --registry-login-server acrmnt.azurecr.io `
    --registry-username 56e6e92f-39c0-43c5-80b6-6a493a28d56c `
    --registry-password 'q6S8Q~NqTCqDmkaJ4TZYjHUacPlGmohfpoc0.bwk' `
    --vnet tfvnetnginx `
    --subnet aci-subnet `
    --port 80

    $aciPrivateIp="$(az container show --name nginxtest `
  --resource-group $resourceGroup `
  --query ipAddress.ip --output tsv)"

  az network vnet subnet create `
  --name AzureFirewallSubnet `
  --resource-group $resourceGroup `
  --vnet-name aci-vnet   `
  --address-prefix 10.0.1.0/26

  az extension add --name azure-firewall

  az network public-ip create `
--resource-group $resourceGroup `
--name fw-pip `
--sku Standard `
--dns-name mentornginx;

  az network firewall create `
  --name myFirewall `
  --resource-group $resourceGroup 

  az network firewall update `
  --name myFirewall `
  --resource-group $resourceGroup `
  --public-ips fw-pip

  az network firewall  list 

  $fwPrivateIp="$(az network firewall ip-config list `
  --resource-group $resourceGroup `
  --firewall-name myFirewall `
  --query "[].privateIpAddress" --output tsv)"


  $fwPublicIp="$(az network public-ip show `
  --name fw-pip `
  --resource-group $resourceGroup `
  --query ipAddress --output tsv)"











#################################################

}




#########################################
######## az cloud shell  ###########

az acr login --name acrmnt     

az acr build --registry acrmnt --image nginxtest:v1 .   
az container attach --name nginxtest --resource-group rgcontainer   
az container logs --name nginxtest --resource-group rgcontainer  
az container exec --name nginxtest --resource-group rgcontainer --exec-command "/bin/bash"
az container list --query [].name --output table  







