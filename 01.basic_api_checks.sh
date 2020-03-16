#**************************************************************************************************************
# Copyright © 2019-2020 Acronis International GmbH. This source code is distributed under MIT software license.
#**************************************************************************************************************

# Basic checks to ensure needed file availability
if test -f api_client.json ; then
	_check_tenant_id=$(_get_tenant_id_from_file api_client.json)

	if [[ "$_check_tenant_id" = "null" ]]; then
		_die "The file api_client.json has incorrect format. Please call 01.create-api-client.sh to create it."
	fi
else
	_die "The file api_client.json doesn't exist. Please call 01.create-api-client.sh to create it."
fi

# Check an authorization token and renew if needed
# Need to have valid api_client.json
_renew_token_if_needed