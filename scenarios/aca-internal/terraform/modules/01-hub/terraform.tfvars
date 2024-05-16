
// The name of the workloard that is being deployed. Up to 10 characters long. This wil be used as part of the naming convention (i.e. as defined here: https://learn.microsoft.com/azure/cloud-adoption-framework/ready/azure-best-practices/resource-naming) 
workloadName = "lzaaca"
//The name of the environment (e.g. "dev", "test", "prod", "preprod", "staging", "uat", "dr", "qa"). Up to 8 characters long.
environment                  = "dev"
tags                         = {}
hubResourceGroupName         = ""
vnetAddressPrefixes          = ["10.0.0.0/24"]
enableBastion                = true
bastionSubnetAddressPrefixes = ["10.0.0.128/26"]
