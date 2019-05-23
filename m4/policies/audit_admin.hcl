#This policy is meant to grant the holder access to add, remove, and 
#configure audit devices within Vault

#Configure audit devices
path "sys/audit/*"
{
    capabilities = ["create", "read", "update", "delete", "list", "sudo"]
}

#List audit configurations
path "sys/config/auditing"
{
    capabilities = ["read","list"]
}
#Configure audit settings for a device
path "sys/config/auditing/*"
{
    capabilities = ["create", "read", "update", "delete", "list", "sudo"]
}