targetScope = 'subscription'

// ------------------
//    PARAMETERS
// ------------------
@description('The name of the workload that is being deployed. Up to 10 characters long.')
@minLength(2)
@maxLength(10)
param workloadName string = 'aca-lza'

@description('The name of the environment (e.g. "dev", "test", "prod", "uat", "dr", "qa"). Up to 8 characters long.')
@maxLength(8)
param environment string = 'test'

@description('The location where the resources will be created.')
param location string =  deployment().location

@description('Optional. The tags to be assigned to the created resources.')
param tags object = {}

@description('Optional. The name of the hub resource group to create the resources in. If set, it overrides the name generated by the template.')
param hubResourceGroupName string = ''

// Hub Virtual Network
@description('The address prefixes to use for the virtual network.')
param vnetAddressPrefixes array

// Hub Bastion
@description('Enable or disable the creation of the Azure Bastion.')
param enableBastion bool

@description('CIDR to use for the Azure Bastion subnet.')
param bastionSubnetAddressPrefix string

@description('CIDR to use for the gatewaySubnet.')
param gatewaySubnetAddressPrefix string

@description('CIDR to use for the azureFirewallSubnet.')
param azureFirewallSubnetAddressPrefix string

@description('CIDR to use for the AzureFirewallManagementSubnet, which is required by AzFW Basic.')
param azureFirewallSubnetManagementAddressPrefix string

// Hub Virtual Machine
@description('The size of the virtual machine to create. See https://learn.microsoft.com/azure/virtual-machines/sizes for more information.')
param vmSize string

@description('The username to use for the virtual machine.')
param vmAdminUsername string

@description('The password to use for the virtual machine.')
@secure()
param vmAdminPassword string

@description('The username to use for the db.')
param postgresAdminUsername string

@description('The password to use for the db.')
@secure()
param postgresAdminPassword string

@description('The SSH public key to use for the virtual machine.')
@secure()
param vmLinuxSshAuthorizedKeys string

@allowed(['linux', 'windows', 'none'])
param vmJumpboxOSType string = 'none'

@description('CIDR to use for the virtual machine subnet.')
param vmJumpBoxSubnetAddressPrefix string

// Spoke
@description('Optional. The name of the resource group to create the resources in. If set, it overrides the name generated by the template.')
param spokeResourceGroupName string = ''

@description('CIDR of the Spoke Virtual Network.')
param spokeVNetAddressPrefixes array

@description('CIDR of the Spoke Infrastructure Subnet.')
param spokeInfraSubnetAddressPrefix string

@description('CIDR of the Spoke db Subnet.')
param spokePostgesSubnetAddressPrefix string

@description('CIDR of the Spoke Private Endpoints Subnet.')
param spokePrivateEndpointsSubnetAddressPrefix string

@description('CIDR of the Spoke Application Gateway Subnet.')
param spokeApplicationGatewaySubnetAddressPrefix string

@description('Enable or disable the createion of Application Insights.')
param enableApplicationInsights bool

@description('Enable or disable Dapr Application Instrumentation Key used for Dapr telemetry. If Application Insights is not enabled, this parameter is ignored.')
param enableDaprInstrumentation bool

@description('Enable or disable the deployment of the Sample App. If disabled, the Application Gateway will not be deployed.')
param deployAcaSample bool

@description('Enable or disable the deployment of the Application Gateway.')
param deployApplicationGateway bool

@description('The FQDN of the Application Gateway. Must match the TLS Certificate.')
param applicationGatewayFqdn string

@description('Enable or disable Application Gateway Certificate (PFX).')
param enableApplicationGatewayCertificate bool

@description('The name of the certificate key to use for Application Gateway certificate.')
param applicationGatewayCertificateKeyName string

@description('Enable usage and telemetry feedback to Microsoft.')
param enableTelemetry bool = true

@description('Deploy Azure Container Registry')
param deployAcr bool = false

@description('Optional, default value is false. If true, Azure Cache for Redis (Premium SKU), together with Private Endpoint and the relavant Private DNS Zone will be deployed')
param deployRedisCache bool = false

@description('Deploy (or not) an Azure OpenAI account. ATTENTION: At the time of writing this, OpenAI is in preview and only available in limited regions: look here: https://learn.microsoft.com/azure/ai-services/openai/chatgpt-quickstart#prerequisites')
param deployOpenAi bool

@description('Optional, default value is true. If true, any resources that support AZ will be deployed in all three AZ. However if the selected region is not supporting AZ, this parameter needs to be set to false.')
param deployZoneRedundantResources bool = true

@description('Optional, default value is true. If true, Azure Policies will be deployed')
param deployAzurePolicies bool = true

@description('Optional. DDoS protection mode. see https://learn.microsoft.com/azure/ddos-protection/ddos-protection-sku-comparison#skus')
@allowed([
  'Enabled'
  'Disabled'
  'VirtualNetworkInherited'
])
param ddosProtectionMode string = 'Disabled'

// ------------------
// VARIABLES
// ------------------
var namingRules = json(loadTextContent('../../shared/bicep/naming/naming-rules.jsonc'))
var rgHubName = !empty(hubResourceGroupName) ? hubResourceGroupName : '${namingRules.resourceTypeAbbreviations.resourceGroup}-${workloadName}-hub-${environment}-${namingRules.regionAbbreviations[toLower(location)]}'
var rgSpokeName = !empty(spokeResourceGroupName) ? spokeResourceGroupName : '${namingRules.resourceTypeAbbreviations.resourceGroup}-${workloadName}-spoke-${environment}-${namingRules.regionAbbreviations[toLower(location)]}'


// ------------------
// RESOURCES
// ------------------
module hub 'modules/01-hub/deploy.hub.bicep' = {
  name: take('hub-${deployment().name}-deployment', 64)
  params: {
    location: location
    tags: tags
    hubResourceGroupName: rgHubName
    environment: environment
    workloadName: workloadName
    vnetAddressPrefixes: vnetAddressPrefixes
    enableBastion: enableBastion
    bastionSubnetAddressPrefix: bastionSubnetAddressPrefix    
    azureFirewallSubnetAddressPrefix: azureFirewallSubnetAddressPrefix
    azureFirewallSubnetManagementAddressPrefix: azureFirewallSubnetManagementAddressPrefix
    gatewaySubnetAddressPrefix: gatewaySubnetAddressPrefix
    spokeInfraSubnetAddressPrefix: spokeInfraSubnetAddressPrefix
  }
}

resource spokeResourceGroup 'Microsoft.Resources/resourceGroups@2020-06-01' = {
  name: rgSpokeName
  location: location
  tags: tags
}

module spoke 'modules/02-spoke/deploy.spoke.bicep' = {
  name: take('spoke-${deployment().name}-deployment', 64)
  params: {
    spokeResourceGroupName: spokeResourceGroup.name
    location: location
    tags: tags
    environment: environment
    workloadName: workloadName
    hubVNetId:  hub.outputs.hubVNetId
    spokeApplicationGatewaySubnetAddressPrefix: spokeApplicationGatewaySubnetAddressPrefix
    spokeInfraSubnetAddressPrefix: spokeInfraSubnetAddressPrefix
    spokePostgresSubnetAddressPrefix: spokePostgesSubnetAddressPrefix
    spokePrivateEndpointsSubnetAddressPrefix: spokePrivateEndpointsSubnetAddressPrefix
    spokeVNetAddressPrefixes: spokeVNetAddressPrefixes
    networkApplianceIpAddress: hub.outputs.networkApplianceIpAddress
    vmSize: vmSize
    vmAdminUsername: vmAdminUsername
    vmAdminPassword: vmAdminPassword
    vmLinuxSshAuthorizedKeys: vmLinuxSshAuthorizedKeys
    vmJumpboxOSType: vmJumpboxOSType
    vmJumpBoxSubnetAddressPrefix: vmJumpBoxSubnetAddressPrefix
    deployAzurePolicies: deployAzurePolicies
  }
}


module supportingServices 'modules/03-supporting-services/deploy.supporting-services.bicep' = {
  name: take('supportingServices-${deployment().name}-deployment', 64)
  scope: spokeResourceGroup
  params: {
    location: location
    tags: tags
    spokePrivateEndpointSubnetName: spoke.outputs.spokePrivateEndpointsSubnetName
    environment: environment
    workloadName: workloadName
    spokeVNetId: spoke.outputs.spokeVNetId
    hubVNetId: hub.outputs.hubVNetId
    spokePostgresSubnetId: spoke.outputs.spokePostgresSubnetId   
    postgresAdminPassword: postgresAdminPassword
    postgresAdminUsername: postgresAdminUsername
    deployRedisCache: deployRedisCache
    logAnalyticsWorkspaceId: spoke.outputs.logAnalyticsWorkspaceId
    deployOpenAi: deployOpenAi
    deployAcr: deployAcr
  }
}

module containerAppsEnvironment 'modules/04-container-apps-environment/deploy.aca-environment.bicep' = {
  name: take('containerAppsEnvironment-${deployment().name}-deployment', 64)
  scope: spokeResourceGroup
  params: {
    location: location
    tags: tags
    environment: environment
    workloadName: workloadName
    hubVNetId:  hub.outputs.hubVNetId
    spokeVNetName: spoke.outputs.spokeVNetName
    spokeInfraSubnetName: spoke.outputs.spokeInfraSubnetName
    enableApplicationInsights: enableApplicationInsights
    enableDaprInstrumentation: enableDaprInstrumentation
    enableTelemetry: enableTelemetry
    logAnalyticsWorkspaceId: spoke.outputs.logAnalyticsWorkspaceId
  }
}


module acaApp 'modules/05-aca-sample-app/deploy.aca.bicep' = if (deployAcaSample) {
  name: take('acaSampleApp-${deployment().name}-deployment', 64)
  scope: spokeResourceGroup
  params: {
    location: location
    tags: tags
    containerAppImage: 'ghcr.io/goncalvesj/sw-rest:4789232788'
    containerAppName: 'aca-sample-app'
    // containerRegistryUserAssignedIdentityId: supportingServices.outputs.containerRegistryUserAssignedIdentityId
    containerAppsEnvironmentId: containerAppsEnvironment.outputs.containerAppsEnvironmentId
  }
}

// Front Door Alternative has a limitation, doesnt work with Workload Profiles, so we need to deploy an Application Gateway
// Create with Certificate throws a Password error when using PFX certs that have password.
// To fix this, enableApplicationGatewayCertificate must be set to false. That deploys an Application Gateway with a HTTP Listener.
// To finish the setup, generate a certificate, upload it to the Certs folder and run the script CHANGE_ME.ps1
// It will upload the certificate to the Key Vault, link it to the Application Gateway and create a HTTPS Listener.
module applicationGateway 'modules/06-application-gateway/deploy.app-gateway.bicep' = if (deployApplicationGateway) {
  name: take('applicationGateway-${deployment().name}-deployment', 64)
  scope: spokeResourceGroup
  params: {
    location: location
    tags: tags
    environment: environment
    workloadName: workloadName
    applicationGatewayCertificateKeyName: applicationGatewayCertificateKeyName
    applicationGatewayFqdn: applicationGatewayFqdn
    applicationGatewayPrimaryBackendEndFqdn: (deployAcaSample) ? acaApp.outputs.acaAppFqdn : 'CHANGE_ME.dev' // To fix issue when hello world is not deployed
    applicationGatewaySubnetId: spoke.outputs.spokeApplicationGatewaySubnetId
    enableApplicationGatewayCertificate: enableApplicationGatewayCertificate
    keyVaultId: supportingServices.outputs.keyVaultId
    deployZoneRedundantResources: deployZoneRedundantResources
    ddosProtectionMode: ddosProtectionMode
    applicationGatewayLogAnalyticsId: spoke.outputs.logAnalyticsWorkspaceId
  }
}

// ------------------
// OUTPUTS
// ------------------


// Hub
@description('The resource ID of hub virtual network.')
output hubVNetId string = hub.outputs.hubVNetId

@description('The name of the Hub resource group.')
output hubResourceGroupName string = hub.outputs.resourceGroupName

// Spoke
@description('The name of the Spoke resource group.')
output spokeResourceGroupName string = spokeResourceGroup.name

@description('The  resource ID of the Spoke Virtual Network.')
output spokeVNetId string = spoke.outputs.spokeVNetId

@description('The name of the Spoke Virtual Network.')
output spokeVnetName string = spoke.outputs.spokeVNetName

@description('The resource ID of the Spoke Infrastructure Subnet.')
output spokeInfraSubnetId string = spoke.outputs.spokeInfraSubnetId

@description('The name of the Spoke Infrastructure Subnet.')
output spokeInfraSubnetName string = spoke.outputs.spokeInfraSubnetName

@description('The name of the Spoke Private Endpoints Subnet.')
output spokePrivateEndpointsSubnetName string = spoke.outputs.spokePrivateEndpointsSubnetName

@description('The resource ID of the Spoke Application Gateway Subnet. If "spokeApplicationGatewaySubnetAddressPrefix" is empty, the subnet will not be created and the value returned is empty.')
output spokeApplicationGatewaySubnetId string = spoke.outputs.spokeApplicationGatewaySubnetId

@description('The name of the Spoke Application Gateway Subnet.  If "spokeApplicationGatewaySubnetAddressPrefix" is empty, the subnet will not be created and the value returned is empty.')
output spokeApplicationGatewaySubnetName string = spoke.outputs.spokeApplicationGatewaySubnetName

// Supporting Services
@description('The resource ID of the container registry.')
output containerRegistryId string = supportingServices.outputs.containerRegistryId

@description('The name of the container registry.')
output containerRegistryName string = supportingServices.outputs.containerRegistryName

@description('The resource ID of the user assigned managed identity for the container registry to be able to pull images from it.')
output containerRegistryUserAssignedIdentityId string = supportingServices.outputs.containerRegistryUserAssignedIdentityId

@description('The resource ID of the key vault.')
output keyVaultId string = supportingServices.outputs.keyVaultId

@description('The name of the key vault.')
output keyVaultName string = supportingServices.outputs.keyVaultName

// Container Apps Environment
@description('The resource ID of the container apps environment.')
output containerAppsEnvironmentId string = containerAppsEnvironment.outputs.containerAppsEnvironmentId

@description('The name of the container apps environment.')
output containerAppsEnvironmentName string = containerAppsEnvironment.outputs.containerAppsEnvironmentName
