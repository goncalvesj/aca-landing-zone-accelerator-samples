az network application-gateway frontend-port list --resource-group rg-hha-spoke-dev-neu --gateway-name agw-hha-dev-neu
az network application-gateway show -n agw-hha-dev-neu -g rg-hha-spoke-dev-neu

az keyvault secret set --vault-name "kv-hha-ckmx6-dev-neu" --name "MySecret" --value "TEST"

az appconfig kv set -n appconf-hha-dev-neu --key color --label MyLabel --value red
az appconfig kv set-keyvault -n appconf-hha-dev-neu --key MySecret --label MyLabel --secret-identifier https://kv-hha-ckmx6-dev-neu.vault.azure.net/secrets/MySecret