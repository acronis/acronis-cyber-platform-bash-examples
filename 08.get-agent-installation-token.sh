#!/bin/bash

#**************************************************************************************************************
# Copyright © 2019-2020 Acronis International GmbH. This source code is distributed under MIT software license.
#**************************************************************************************************************

. 00.basis_functions.sh

. 01.basic_api_checks.sh

# Get Root personal_tenant_id for a user
_user_personal_tenant_id=$(_get_personal_tenant_id_from_file user.json)

# Construct JSON to request a token
_json='{
  "tenant_id": "'$_user_personal_tenant_id'",
  "expires_in": 3600,
  "scopes": [
    "urn:acronis.com:tenant-id::backup_agent_admin"
  ]
}'

# To create an agent installation token
# POST API call using function defined in basis_functions.sh
# with following parameters
# $1 - an API endpoint to call
# $2 - Content-Type
# $3 - POST data
# The result is stored in created_report.json file
_post_api_call_bearer_bc "bc/api/account_server/registration_tokens" \
					"application/json" \
					"${_json}" > agent_installation_token.json
