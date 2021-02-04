#!/bin/bash

#**************************************************************************************************************
# Copyright © 2019-2020 Acronis International GmbH. This source code is distributed under MIT software license.
#**************************************************************************************************************

. 00.basis_functions.sh

. 01.basic_api_checks.sh

# Call a function to pipe JSON from file, extract JSON property
_user_id=$(_get_id_from_file user.json)

_personal_tenant_id=$(jq '.personal_tenant_id' < user.json | sed -e 's/^"//' -e 's/"$//')

_json='{"items": [
     {"id": "00000000-0000-0000-0000-000000000000",
     "issuer_id": "00000000-0000-0000-0000-000000000000",
     "role_id": "backup_user",
     "tenant_id": "'${_personal_tenant_id}'",
     "trustee_id": "'${_user_id}'",
     "trustee_type": "user",
     "version": 0}
     ]}'

_put_api_call_bearer "api/2/users/${_user_id}/access_policies" \
					"application/json" \
					"${_json}"
