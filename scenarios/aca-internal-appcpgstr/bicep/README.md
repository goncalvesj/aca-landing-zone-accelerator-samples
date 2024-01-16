# Azure Container Apps - Internal environment with App Config, Azure PostgreSQL, and Azure Storage [Bicep]

This is the Bicep-based deployment guide for [Scenario 3: Azure Container Apps - Internal environment with App Config, Azure PostgreSQL, and Azure Storage](../README.md).

## Quick deployment to Azure

### Deploy with the Azure Developer CLI (using Codespaces or in your local machine)

You can deploy the current LZA directly in your Azure subscription using Azure Dev CLI.

If using GH Codespaces, you can use the following steps:

- Visit [github.com/Azure/aca-landing-zone-accelerator](https://github.com/goncalvesj/aca-landing-zone-accelerator-samples)
- Click on the `Green Code` button.
- Navigate to the `CodeSpaces` tab and create a new code space.
- Open the terminal by pressing ``Ctrl + ` ``.

If using your local machine, you can use the following steps:

- Clone the repo locally.
- Navigate to the scenario folder using the command `cd aca-landing-zone-accelerator-samples/scenarios/aca-internal-appcpgstr`.
- Login to Azure using the command `azd auth login`.
- Use the command `azd up` to deploy, provide environment name and subscription to deploy to.
- Finally, use the command `azd down` to clean up resources deployed.

## Prerequisites

This is the starting point for the instructions on deploying this reference implementation. There is required access and tooling you'll need in order to accomplish this.

- An Azure subscription
- The following resource providers [registered](https://learn.microsoft.com/azure/azure-resource-manager/management/resource-providers-and-types#register-resource-provider):
  - `Microsoft.App`
  - `Microsoft.ContainerRegistry`
  - `Microsoft.ContainerService`
  - `Microsoft.KeyVault`
- The user or service principal initiating the deployment process must have the [owner role](https://learn.microsoft.com/azure/role-based-access-control/built-in-roles#owner) at the subscription level to have the ability to create resource groups and to delegate access to others (Azure Managed Identities created from the IaC deployment).
- Latest [Azure CLI installed](https://learn.microsoft.com/cli/azure/install-azure-cli?view=azure-cli-latest) (must be at least 2.40), or you can perform this from Azure Cloud Shell by clicking below.

  [![Launch Azure Cloud Shell](https://learn.microsoft.com/azure/includes/media/cloud-shell-try-it/launchcloudshell.png)](https://shell.azure.com)

## Steps

1. Clone/download this repo locally, or fork this repository.

   > :twisted_rightwards_arrows: If you have forked this reference implementation repo, you can configure the provided GitHub workflow. Ensure references to this git repository mentioned throughout the walk-through are updated to use your own fork.

2. Update naming convention. *Optional.*

   The naming of the resources in this implementation follows the Cloud Adoption Framework's resource [naming convention](https://learn.microsoft.com/azure/cloud-adoption-framework/ready/azure-best-practices/resource-naming). Your organization might have a naming strategy in place, which possibly deviates from this implementation. In most cases you can modified what is deployed by modifying the following two files:

   - [**naming.module.bicep**](../../shared/bicep/naming/naming.module.bicep) contains the naming convention.
   - [**naming-rules.jsonc**](../../shared/bicep/naming/naming-rules.jsonc) contains the [abbreviations](https://learn.microsoft.com/azure/cloud-adoption-framework/ready/azure-best-practices/resource-abbreviations) for resources (`resourceTypeAbbreviations`) and Azure regions (`regionAbbreviations`) used in the naming convention.

3. :world_map: Choose your deployment experience.

   This reference implementation comes with *three* implementation deployment options. They all result in the same resources and architecture, they simply differ in their user experience; specifically how much is abstracted from your involvement.

   - Follow the "[**Standalone deployment guide**](#standalone-deployment-guide)" if you'd like to simply configure a set of parameters and execute a single CLI command to deploy.

     *This will be your simplest deployment approach, but also the most opaque. This is optimized for "cut to the end."*

   - Follow the "[**Standalone deployment guide with GitHub Actions**](#standalone-deployment-guide-with-github-actions)" if you'd like to simply configure a set of parameters and have GitHub Actions execute the deployment.

     *This is a variant of the above. A **fork** of this repo is required for this option, and requires you to create a service principal with appropriate permissions in your Azure Subscription to perform the deployment.*

   - Follow the "[**Standalone deployment guide with Azure Pipelines**](#standalone-deployment-guide-with-azure-pipelines)" if you'd like to simply configure a set of parameters and have Azure Pipelines execute the deployment.

     *This is a variant of the first deployment experience. A **fork** of this repo is required for this option, and requires you to create an appropriate [service connection](https://learn.microsoft.com/azure/devops/pipelines/library/service-endpoints?view=azure-devops&tabs=yaml) for the pipeline to connect to your Azure subscription.*

   - Follow the "[**Step-by-step deployment guide**](#step-by-step-deployment-guide)" if you'd like to walk through the deployment at a slower, more deliberate pace.

     *This will approach will allow you to see the deployment evolve over time, which might give you an insight into the various roles and people in your organization that you need to engage when bringing your workload in this architecture to Azure. This is optimized for "learning."*

   All of these options allow you to deploy to a single subscription, to experience the full architecture in isolation. Adapting this deployment to your Azure landing zone implementation is not required to complete the deployments.

## Deployment experiences

### Standalone deployment guide

1. Log into Azure from the AZ CLI and select your subscription.

   ```bash
   az login
   ```

2. Review and update deployment parameters.

   The [**main.bicepparam**](./main.bicepparam) parameter file is where you can customize your deployment. The defaults are a suitable starting point, but feel free to adjust any to fit your requirements.

3. Deploy the reference implementation.

   This will deploy all of the infrastructure to your selected subscription. This will take over 10 minutes to execute.

   ```bash
   LOCATION=northeurope # or any location that suits your needs
   LZA_DEPLOYMENT_NAME=bicepAcaLzaUDRDeployment  # or any other value that suits your needs
   
   az deployment sub create \
       --template-file main.bicep \
       --location $LOCATION \
       --name $LZA_DEPLOYMENT_NAME \
       --parameters ./main.bicepparam
   ```

#### :broom: Clean up resources

Before cleaning up the resources you might wish to [verify the Azure Firewall Rules](#rotating_light-verify-your-firewall-is-blocking-outbound-traffic)

When you are done exploring the resources created by the Standalone deployment guide, use the following command to remove the resources you created.

```bash
$LZA_DEPLOYMENT_NAME=bicepAcaLzaDeployment  # The name of the deployment you used in the previous step

# get the name of the Spoke Resource Group that has been created previously
SPOKE_RESOURCE_GROUP_NAME=$(az deployment sub show -n "$LZA_DEPLOYMENT_NAME" --query properties.outputs.spokeResourceGroupName.value -o tsv)

# get the name of the Hub Resource Group that has been created previously
HUB_RESOURCE_GROUP_NAME=$(az deployment sub show -n "$LZA_DEPLOYMENT_NAME" --query properties.outputs.hubResourceGroupName.value -o tsv)

az group delete -n $SPOKE_RESOURCE_GROUP_NAME
az group delete -n $HUB_RESOURCE_GROUP_NAME
```

### Standalone deployment guide with GitHub Actions

Follow the same steps for Scenario 1 but adapt to this folder.

#### :broom: Clean up resources

Before cleaning up the resources you might wish to [verify the Azure Firewall Rules](#rotating_light-verify-your-firewall-is-blocking-outbound-traffic)

If you didn't select automatic clean up of the deployed resources, use the following commands to remove the resources you created.

```bash
az group delete -n <your-spoke-resource-group>
az group delete -n <your-hub-resource-group>
```

### Standalone deployment guide with Azure Pipelines

Follow the same steps for Scenario 1 but adapt to this folder.

#### :broom: Clean up resources

Before cleaning up the resources you might wish to [verify the Azure Firewall Rules](#rotating_light-verify-your-firewall-is-blocking-outbound-traffic)

Use the following commands to remove the resources you created.

```bash
az group delete -n <your-spoke-resource-group>
az group delete -n <your-hub-resource-group>
```

### Step-by-step deployment guide

These instructions are spread over a series of dedicated pages for each step along the way. With this method of deployment, you can leverage the step-by-step process considering where possibly different teams (devops, network, operations etc.) with different levels of access, are required to coordinate and deploy all of the required resources.

:arrow_forward: This starts with [Deploy the hub networking resources](./modules/01-hub/README.md).

## :rotating_light: Verify your firewall is blocking outbound traffic

If you have deployed the *Sample Application* and you wish to verify your Azure Firewall configuration is set up correctly, you can use the ```curl``` command from your app's debugging console. Follow the steps below:

1. Navigate to your Container App that is configured with Azure Firewall.

1. From the menu on the left, select Console, then select your container that supports the curl command.

1. In the Choose start up command menu, select ```/bin/sh```, and select Connect.

1. In the console, run ```curl -s https://mcr.microsoft.com```. You should see a successful response (because the default LZA deployment adds the application rule *ace-allow-rules* which among others adds ```mcr.microsoft.com``` to the allow list for your firewall policies). If you get an error that curl is not found in the container's shell, follow the next steps to install it.
   > a. Run ```apk add curl``` to add the curl package. If you get an error, most possibly some URL is being blocked by your firewall, so let's investigate that.
   > b. Got to your hub, find your azure firewall, and click on the logs. there run the following query:

   ```KQL
   AzureDiagnostics
   | where Category == "AzureFirewallNetworkRule" or Category == "AzureFirewallApplicationRule"
   | extend msg_original = msg_s
   | extend msg_s = replace(@'. Action: Deny. Reason: SNI TLS extension was missing.', @' to no_data:no_data. Action: Deny. Rule Collection: default behavior. Rule: SNI TLS extension missing', msg_s)
   | extend msg_s = replace(@'No rule matched. Proceeding with default action', @'Rule Collection: default behavior. Rule: no rule matched', msg_s)
   | parse msg_s with * " Web Category: " WebCategory
   | extend msg_s = replace(@'(. Web Category:).*','', msg_s)
   | parse msg_s with * ". Rule Collection: " RuleCollection ". Rule: " Rule
   | extend msg_s = replace(@'(. Rule Collection:).*','', msg_s)
   | parse msg_s with * ". Rule Collection Group: " RuleCollectionGroup
   | extend msg_s = replace(@'(. Rule Collection Group:).*','', msg_s)
   | parse msg_s with * ". Policy: " Policy
   | extend msg_s = replace(@'(. Policy:).*','', msg_s)
   | parse msg_s with * ". Signature: " IDSSignatureIDInt ". IDS: " IDSSignatureDescription ". Priority: " IDSPriorityInt ". Classification: " IDSClassification
   | extend msg_s = replace(@'(. Signature:).*','', msg_s)
   | parse msg_s with * " was DNAT'ed to " NatDestination
   | extend msg_s = replace(@"( was DNAT'ed to ).*",". Action: DNAT", msg_s)
   | parse msg_s with * ". ThreatIntel: " ThreatIntel
   | extend msg_s = replace(@'(. ThreatIntel:).*','', msg_s)
   | extend URL = extract(@"(Url: )(.*)(\. Action)",2,msg_s)
   | extend msg_s=replace(@"(Url: .*)(Action)",@"\2",msg_s)
   | parse msg_s with Protocol " request from " SourceIP " to " Target ". Action: " Action
   | extend 
      SourceIP = iif(SourceIP contains ":",strcat_array(split(SourceIP,":",0),""),SourceIP),
      SourcePort = iif(SourceIP contains ":",strcat_array(split(SourceIP,":",1),""),""),
      Target = iif(Target contains ":",strcat_array(split(Target,":",0),""),Target),
      TargetPort = iif(SourceIP contains ":",strcat_array(split(Target,":",1),""),""),
      Action = iif(Action contains ".",strcat_array(split(Action,".",0),""),Action),
      Policy = case(RuleCollection contains ":", split(RuleCollection, ":")[0] ,Policy),
      RuleCollectionGroup = case(RuleCollection contains ":", split(RuleCollection, ":")[1], RuleCollectionGroup),
      RuleCollection = case(RuleCollection contains ":", split(RuleCollection, ":")[2], RuleCollection),
      IDSSignatureID = tostring(IDSSignatureIDInt),
      IDSPriority = tostring(IDSPriorityInt)
   | project TimeGenerated,Protocol,SourceIP,SourcePort,Target,TargetPort,URL,Action, NatDestination, OperationName,ThreatIntel,IDSSignatureID,IDSSignatureDescription,IDSPriority,IDSClassification,Policy,RuleCollectionGroup,RuleCollection,Rule,WebCategory, msg_original
   | where Action == "Deny"
   | order by TimeGenerated desc
   | limit 100      
   ```

   > You should find some calls t with target fqdn ```dl-cdn.alpinelinux.org``` that are being blocked. This already verifies that the firewall is successfully filtering the egress traffic, but let's fix that, and add ```curl``` in your container.
   >c. Go to the Azure Firewall > Settings > Rules     (Classic) > Application Rule Connection and add an application rule that permits calls to ```dl-cdn.alpinelinux.org``` with http:80 and https:443 protocols. Wait for the rule to be updated/created and then try again to install curl (```apk add curl```).
   >d. Once *curl* is installed run again ```curl -s https://mcr.microsoft.com```,  you should see a successful response.

1. Run ```curl -s https://www.docker.com``` (for a URL that doesn't match any of your destination rules). You should get no response, which indicates that your firewall has blocked the request. If you wish you can check the Firewall's logs (with the query found in the previous step) to verify that your call to <www.docker.com> has been denied.
