#!/bin/bash

#**************************************************************************************************************
# Copyright © 2019-2020 Acronis International GmbH. This source code is distributed under MIT software license.
#**************************************************************************************************************

. 00.basis_functions.sh

# Ask the user for login details
# To use for Basic Authentication
# To create an API Client
printf "\n"
read -rp 'Login: ' _login
read -rsp 'Password: ' _password

# Request self-ifo from API using Basic Authentication
# GET call using function defined in basis_functions.sh
# with following parameters
# $1 - an API endpoint to call
# $2 - a login for Basic Authentication
# $3 - a password for Basic Authentication
# The result is going to jq utility to extract JSON property
# Please NOTE, that this property is retrieved with quotas
_tenant_id=$(_get_api_call_basic "api/2/users/me" "${_login}" "${_password}" | jq '.tenant_id')

# Construct JSON to request an API Client creation
_json='{
		"type": "api_client",
		"tenant_id": '$_tenant_id',
		"token_endpoint_auth_method": "client_secret_basic",
		"data": {
				"client_name": "Acronis.GitHub.Bash.Examples.v2"
				}
	  }'

# To create an API Client
# GET call using function defined in basis_functions.sh
# with following parameters
# $1 - an API endpoint to call
# $2 - a login for Basic Authentication
# $3 - a password for Basic Authentication
# The result is stored in api_client.json file
_post_api_call_basic "api/2/clients" \
					"${_login}" "${_password}" \
					"${_json}" \
					"application/json" > api_client.json