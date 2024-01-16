## Variables
## Retrieve them after Bicep deployment is finished

$appgwname = 'agw-hha-dev-neu'
$appgwrg = 'rg-hha-spoke-dev-neu'
$appgwnuserassignedidentity = 'id-agw-hha-dev-neu-KeyVaultSecretUser'
$frontendPortName='port_443'
$frontendIp='appGwPublicFrontendIp'
$keyVaultName='kv-hha-ckmx6-dev-neu'
$keyVaultSecretUserRoleGuid='4633458b-17de-408a-b874-0445c86b69e6'

$certpassword = 'CHANGEME'
$certfile='../scenarios/aca-internal-appcpgstr/certs/aca-sw-rest.pfx'
$sslname='aca-sw-rest'
$domain='aca-sw-rest.jprg.xyz'

## Upload certs to Key Vault
az keyvault certificate import --vault-name $keyVaultName --name $sslname --file $certfile --password $certpassword

## Get Secret ID from Key Vault
## Remove the secret version so AppGW will use the latest version
$secret=$(az keyvault secret show --name $sslname --vault-name $keyVaultName --query id -o tsv)
$secretId = Split-Path $secret -Parent
$secretId = $secretId.Replace("\", "/")

## Link the certificate to the Application Gateway
## Needs access to KV using a User Assigned Managed Identity

## Get the Key Vault's and User Managed Identity resource ID
$keyVaultId=$(az keyvault show --name $keyVaultName --query id -o tsv)
$assigneeObjectId=$(az identity show -n $appgwnuserassignedidentity -g $appgwrg --query principalId -o tsv)

## Add RBAC role assignment for the user assigned managed identity to the Key Vault
az role assignment create --assignee-principal-type 'ServicePrincipal' --assignee-object-id $assigneeObjectId --role $keyVaultSecretUserRoleGuid --scope $keyVaultId

## Add the certificate to the Application Gateway
az network application-gateway ssl-cert create --gateway-name $appgwname --resource-group $appgwrg --name $sslname --key-vault-secret-id $secretId

## Create Frontend Port if not exists
az network application-gateway frontend-port create -g $appgwrg --gateway-name $appgwname -n $frontendPortName --port 443

## Create HTTPS Listener
az network application-gateway http-listener create -g $appgwrg --gateway-name $appgwname --frontend-port $frontendPortName -n $domain.Replace('.','') --frontend-ip $frontendIp --ssl-cert $sslname --host-name $domain

## Create Rule
az network application-gateway rule create -g $appgwrg --gateway-name $appgwname -n MyRule --http-listener $domain.Replace('.','') --rule-type Basic --address-pool 'acaServiceBackend' --http-settings 'https' --priority 1

# Commit the changes to the Application Gateway
az network application-gateway update --name $appgwname --resource-group $appgwrg
