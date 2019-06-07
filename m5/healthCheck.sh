#Bash
curl https://vault-vms.globomantics.xyz:8200/v1/sys/health | jq

#PowerShell
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$resp = Invoke-WebRequest https://vault-vms.globomantics.xyz:8200/v1/sys/health
$resp.Content | ConvertFrom-Json