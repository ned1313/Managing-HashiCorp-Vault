#Create the policies
vault policy write full_admin full_admin.hcl
vault policy write engine_admin engine_admin.hcl
vault policy write audit_admin audit_admin.hcl
vault policy write helpdesk_admin helpdesk_admin.hcl

#Create internal groups
vault write identity/group name=full_admins policies=full_admin
vault write identity/group name=engine_admins policies=engine_admin
vault write identity/group name=audit_admins policies=audit_admin
vault write identity/group name=helpdesk_admins policies=helpdesk_admin

#Enable the userpass auth method and create four users
vault auth enable userpass
vault write auth/userpass/users/arthur password=dent
vault write auth/userpass/users/ford password=prefect
vault write auth/userpass/users/tricia password=mcmillian
vault write auth/userpass/users/zaphod password=beeblebrox

#Create entities and aliases for the users
vault read sys/auth
vault write identity/entity name=arthur
vault write identity/entity-alias name=arthur mount_accessor=ACCESSOR_ID canonical_id=ENTITY_ID
vault write identity/group name=full_admins member_entity_ids=ENTITY_ID

#Login as Arthur and check policy assignment
vault login -method=userpass username=arthur

vault write identity/entity name=ford
vault write identity/entity-alias name=ford mount_accessor=ACCESSOR_ID canonical_id=ENTITY_ID
vault write identity/group name=engine_admins member_entity_ids=ENTITY_ID

vault write identity/entity name=tricia
vault write identity/entity-alias name=tricia mount_accessor=ACCESSOR_ID canonical_id=ENTITY_ID
vault write identity/group name=audit_admins member_entity_ids=ENTITY_ID

vault write identity/entity name=zaphod
vault write identity/entity-alias name=zaphod mount_accessor=ACCESSOR_ID canonical_id=ENTITY_ID
vault write identity/group name=helpdesk_admins member_entity_ids=ENTITY_ID

#Login as ford and show permissions
vault login -method=userpass username=ford
vault read sys/auth
vault token lookup

