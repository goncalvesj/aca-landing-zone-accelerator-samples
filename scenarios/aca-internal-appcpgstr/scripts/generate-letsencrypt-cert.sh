## Generate Cert with openssl and Let's Encrypt in WSL

## Generate challenge, needs manual intervention
sudo certbot certonly --manual --agree-tos --preferred-challenges dns -d hello-aca.jprg.xyz

## Create DNS TXT record
## Validate propagation of DNS TXT record in https://mxtoolbox.com/SuperTool.aspx
## Continue process in terminal with certbot

## Convert to pfx,  go to Let's Encrypt folder
sudo openssl pkcs12 -export -in cert.pem -inkey privkey.pem -out hello-aca.pfx

## If there's issues with file permissions run 
sudo chmod -R 777 /etc/letsencrypt/live

## Copy pfx to the scenarios/aca-internal-appcpgstr/certs a folder
## Run app-gw-certs.ps1 in PowerShell to upload to Azure Key Vault
