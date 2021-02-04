#!/bin/bash

#**************************************************************************************************************
# Copyright © 2019-2020 Acronis International GmbH. This source code is distributed under MIT software license.
#**************************************************************************************************************

. 00.basis_functions.sh

. 01.basic_api_checks.sh

# Set response code to 400 -- login availability check failed
_response_code=400

# Ask for proposed username
printf "\n"
read -rp 'Username: ' _username
printf "\n\n"

# To get an availability status of a username
# GET call using function defined in basis_functions.sh
# with following parameters
# $1 - an API endpoint to call
_get_api_call_bearer_with_response_code "api/2/users/check_login?username=${_username}" \
										| {
											read -r _response_code
											read -r # here we would read the response body if need it
											if [[ $_response_code != 204 ]] ; then
  												_die  "The username ${_username} is already exists."
											fi
										}

# Here we can be only if _username is available

# Call a function to pipe JSON from file, extract JSON property
_customer_tenant_id=$(_get_id_from_file customer.json)


# Construct JSON to request a user creation
_json='{
		"tenant_id": "'$_customer_tenant_id'",
		"login": "'${_username}'",
		"contact": {
      				"email": "'${_username}'@example.com"
					}
	  }'

# To create a user
# POST API call using function defined in basis_functions.sh
# with following parameters
# $1 - an API endpoint to call
# $2 - Content-Type
# $3 - POST data
# The result is stored in user.json file
_post_api_call_bearer "api/2/users" \
					"application/json" \
					"${_json}" > user.json

# Call a function to pipe JSON from file, extract JSON property
_user_id=$(_get_id_from_file user.json)

# Body JSON, to assign a password and activate the user
# NEVER STORE A PASSWORD IN PLAIN TEXT FILE
# THIS CODE IS FOR API DEMO PURPOSES ONLY
# AS IT USES FAKE E-MAIL AND ACTIVATION E-MAIL CAN'T BE SENT
_json='{
  		"password": "MyStrongP@ssw0rd"
	   }'

# To activate a user by setting a password
# POST API call using function defined in basis_functions.sh
# with following parameters
# $1 - an API endpoint to call
# $2 - Content-Type
# $3 - POST data
_post_api_call_bearer "api/2/users/${_user_id}/password" \
					"application/json" \
					"${_json}"