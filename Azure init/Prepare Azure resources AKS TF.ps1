az login
az disconnect

az account show --output table

$tenantID = "8c148fc9-fbaf-47ad-8058-f87ff06e3789"
$subscID = "9ecd8630-fa34-4774-889b-81b7d45c0e79"

az group create -l westeurope -n RGManagement
az group create -l westeurope -n RGContainer

$resourceGroup="RGContainer"


#################################################
###   Azure terraform env #######################
#https://thomasthornton.cloud/2021/03/19/deploy-terraform-using-github-actions-into-azure/

az storage account create -n samentordevtfstate -g $resourceGroup -l WestEurope --sku Standard_LRS
 
# Create Storage Account Container
az storage container create -n contmentordevtfstate --account-name samentordevtfstate


az storage account create -n samentorprodtfstate -g $resourceGroup -l WestEurope --sku Standard_LRS
 
# Create Storage Account Container
az storage container create -n contmentorprodtfstate --account-name samentorprodtfstate

az ad sp create-for-rbac --name sptf --role Contributor --scopes /subscriptions/$subscID --sdk-auth

<#
{
  "clientId": "510db0aa-ff39-4980-9c66-32b6dafc141b",
  "clientSecret": "qubeC5YpVznNa28Wbb6UiO_HB8PBFA.f6w",
  "subscriptionId": "9ecd8630-fa34-4774-889b-81b7d45c0e79",
  "tenantId": "8c148fc9-fbaf-47ad-8058-f87ff06e3789",
  "activeDirectoryEndpointUrl": "https://login.microsoftonline.com",
  "resourceManagerEndpointUrl": "https://management.azure.com/",
  "activeDirectoryGraphResourceId": "https://graph.windows.net/",
  "sqlManagementEndpointUrl": "https://management.core.windows.net:8443/",
  "galleryEndpointUrl": "https://gallery.azure.com/",
  "managementEndpointUrl": "https://management.core.windows.net/"
}
#>

#az network firewall ip-config list `
#  --resource-group $resourceGroup `
#  --firewall-name tffwnginx `
# --query "[].privateIpAddress" --output tsv
##########################################################################


############################################
###############       ACR     ##############

$acrName = "acrmnt"
az group create -l westeurope -n RGContainer

az acr create --resource-group RGContainer --name $acrName --sku Basic

$groupId=$(az group show `
  --name RGContainer `
  --query id --output tsv)

az ad sp create-for-rbac `
  --name githubacraccess `
  --scope $groupId `
  --role Contributor `
  --sdk-auth

{
  "clientId": "8e9c7d6a-7624-4567-ae09-65903c140d49",
  "clientSecret": "blWPt2u8OT.o1_qP.Ohp53LKAQiLr_IEqP",
  "subscriptionId": "9ecd8630-fa34-4774-889b-81b7d45c0e79",
  "tenantId": "8c148fc9-fbaf-47ad-8058-f87ff06e3789",
  "activeDirectoryEndpointUrl": "https://login.microsoftonline.com",
  "resourceManagerEndpointUrl": "https://management.azure.com/",
  "activeDirectoryGraphResourceId": "https://graph.windows.net/",
  "sqlManagementEndpointUrl": "https://management.core.windows.net:8443/",
  "galleryEndpointUrl": "https://gallery.azure.com/",
  "managementEndpointUrl": "https://management.core.windows.net/"
}


$spClientID = "8e9c7d6a-7624-4567-ae09-65903c140d49"

$registryId=$(az acr show --name $acrName `
  --query id --output tsv)

az role assignment create `
  --assignee $spClientID  `
  --scope $registryId `
  --role AcrPush

$rgdevId=$(az group show --name RGdev `
  --query id --output tsv)

az role assignment create `
  --assignee $spClientID  `
  --scope $rgdevId `
  --role Contributor

$rgprodId=$(az group show --name RGprod `
  --query id --output tsv)

az role assignment create `
  --assignee $spClientID  `
  --scope $rgprodId `
  --role Contributor

# delete resources
$gr = az group list --query '[].name' -o tsv


foreach ($g in $gr)
{
  $g
  "------"
  az group delete --name  $g -y

}

