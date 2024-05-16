// The name of the workloard that is being deployed. Up to 10 characters long. This wil be used as part of the naming convention (i.e. as defined here: https://learn.microsoft.com/azure/cloud-adoption-framework/ready/azure-best-practices/resource-naming) 
workloadName = "lzaaca"
//The name of the environment (e.g. "dev", "test", "prod", "preprod", "staging", "uat", "dr", "qa"). Up to 8 characters long.
environment            = "dev"
spokeResourceGroupName = "rg-lzaaca-spoke-dev-eus"
appInsightsName        = "appInsightsAca"
hubVnetId              = "<Hub VNET ID>"
spokeVnetId            = "<Spoke VNET ID>"
spokeInfraSubnetId     = "<Spoke Infrstructure Subnet ID>"
tags                   = {}
