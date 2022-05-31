az login


az account show --output table

az group create -l westeurope -n RGManagement

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
--name PIPVMadmin;

az network public-ip update -g RGManagement -n PIPVMadmin `
 --dns-name jenkinsmnt

# Create a network security group.
az network nsg create `
--resource-group RGManagement `
--name VMadminNSG;

# Create a virtual network card and associate with a public IP address and NSG.
az network nic create `
--resource-group RGManagement `
--name NicVMadmin `
--vnet-name VNETManagement `
--subnet snManagement `
--network-security-group NSGManagement `
--public-ip-address PIPVMadmin;

#az vm image list -f Ubuntu --all --location westeurope --all -otable;
#az vm image list -f "Windows-10" --location westeurope --all -otable
#az account list-locations
az vm create `
  --resource-group "RGManagement" `
  --name "VMadmin" `
  --image "MicrosoftWindowsDesktop:Windows-10:win10-21h2-pro-g2:19044.1586.220303" `
  --admin-username "dizen" `
  --admin-password "Install_mnt1" `
  --location westeurope `
  --size Standard_D2as_v5

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
#az vm identity assign --resource-group myResourceGroup --name myDockerVM --identities $userID

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


