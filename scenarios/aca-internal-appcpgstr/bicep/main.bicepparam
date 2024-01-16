using './main.bicep'

param workloadName = 'hha'
param environment = 'dev'
param tags = {}
param enableTelemetry = false
param hubResourceGroupName = ''
param spokeResourceGroupName = ''
param vnetAddressPrefixes = [
  '10.0.0.0/24'
]

// Hub Params
param gatewaySubnetAddressPrefix = '10.0.0.0/27'
param azureFirewallSubnetAddressPrefix = '10.0.0.64/26'
param azureFirewallSubnetManagementAddressPrefix = '10.0.0.128/26'
param bastionSubnetAddressPrefix = '10.0.0.192/26'

// Jumpbox Params
// Bastion dev tier doesnt support peering so we need to deploy it manually in the the spoke vnet
// To switch to the standard tier, change the environment to 'prod'
param enableBastion = false
param vmSize = 'Standard_B2ms'
param vmAdminUsername = 'azureuser'
param vmAdminPassword = 'Password123'
param vmLinuxSshAuthorizedKeys = 'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDpNpoh248rsraL3uejAwKlla+pHaDLbp4DM7bKFoc3Rt1DeXPs0XTutJcNtq4iRq+ooRQ1T7WaK42MfQQxt3qkXwjyv8lPJ4v7aElWkAbxZIRYVYmQVxxwfw+zyB1rFdaCQD/kISg/zXxCWw+gdds4rEy7eq23/bXFM0l7pNvbAULIB6ZY7MRpC304lIAJusuZC59iwvjT3dWsDNWifA1SJtgr39yaxB9Fb01UdacwJNuvfGC35GNYH0VJ56c+iCFeAnMXIT00cYuHf0FCRTP0WvTKl+PQmeD1pwxefdFvKCVpidU2hOARb4ooapT0SDM1SODqjaZ/qwWP18y/qQ/v imported-openssh-key'
param vmJumpboxOSType = 'linux'
param vmJumpBoxSubnetAddressPrefix = '10.1.2.32/27'

// Spoke Params
param spokeVNetAddressPrefixes = [
  '10.1.0.0/22'
]
param spokeInfraSubnetAddressPrefix = '10.1.0.0/27'
param spokePrivateEndpointsSubnetAddressPrefix = '10.1.2.0/27'
param spokeApplicationGatewaySubnetAddressPrefix = '10.1.3.0/24'
param spokePostgesSubnetAddressPrefix = '10.1.1.0/28' // Minimum size for Azure Database for PostgreSQL is /28
param postgresAdminUsername = 'azureuser'
param postgresAdminPassword = 'Password123'
//param spokePostgesARecord = '10.1.1.4' // IP address of the A record for the PostgreSQL server, generated automatically during deployment

// Support Services Params
param deployAcr = false
param deployRedisCache = false
param deployOpenAi = false
param deployAzurePolicies = false
param deployZoneRedundantResources = false
// param deployPostgres = false

// ACA Params
param enableApplicationInsights = false
param enableDaprInstrumentation = false
param deployAcaSample = true

// Application Gateway Params
param deployApplicationGateway = true
param enableApplicationGatewayCertificate = false
param applicationGatewayFqdn = 'hello-aca.jprg.xyz'
param ddosProtectionMode = 'Disabled'
param applicationGatewayCertificateKeyName = 'hello-aca'

