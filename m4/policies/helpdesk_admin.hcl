#This policy is meant to grant a heldesk user access to handle
#basic support issues with Vault.  They can work on auth backends,
#view policies, and manage engine mounts.  They cannot delete existing 
#items in all cases.

# Manage existing auth backends but not add new ones
path "auth/*"
{
  capabilities = ["read", "update", "list"]
}

# List and update auth backends
path "sys/auth/*"
{
  capabilities = ["read", "update"]
}

# List existing policies
path "sys/policy"
{
  capabilities = ["read"]
}

# Manage secret backends including creation, but not deletion
path "sys/mounts/*"
{
  capabilities = ["create", "read", "update", "list"]
}

# Read health checks
path "sys/health"
{
  capabilities = ["read"]
}