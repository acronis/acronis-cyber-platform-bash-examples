#!/bin/bash

#**************************************************************************************************************
# Copyright © 2019-2020 Acronis International GmbH. This source code is distributed under MIT software license.
#**************************************************************************************************************

. 00.basis_functions.sh

. 01.basic_api_checks.sh

# Call a function to pipe JSON from file, extract JSON property
_tenant_id=$(_get_tenant_id_from_file api_client.json)

# Construct JSON to request a partner tenant creation
_json='{
		"name": "MyBashPartner",
		"parent_id": "'$_tenant_id'",
		"kind": "partner"
	}'

# To create a partner tenant
# POST API call using function defined in basis_functions.sh
# with following parameters
# $1 - an API endpoint to call
# $2 - Content-Type
# $3 - POST data
# The result is stored in partner.json file
_post_api_call_bearer "api/2/tenants" \
					"application/json" \
					"${_json}" > partner.json

# Get Kind of a tenant from config file
_kind=$(_config_get_value partner_tenant)

# Get Edition we plan to enable from config file
_edition=$(_config_get_value edition)

# To get a list of offering ite,s available for a child tenant
# GET call using function defined in basis_functions.sh
# with following parameters
# $1 - an API endpoint to call

# The result is stored in offering_items_available_for_child.json file
_get_api_call_bearer "api/2/tenants/${_tenant_id}/offering_items/available_for_child?kind=${_kind}&edition=${_edition}" \
					 > offering_items_available_for_child.json


# Replace "items" with "offering_items" as the following API call expects to have it as a root JSON element
 sed 's/"items"/"offering_items"/g' < offering_items_available_for_child.json > offering_items_to_put.json


# Call a function to pipe JSON from file, extract JSON property
_partner_tenant_id=$(_get_id_from_file partner.json)

# To update offering item for a tenant
# PUT API call using function defined in basis_functions.sh
# with following parameters
# $1 - an API endpoint to call
# $2 - Content-Type
# $4 - PUT data
_put_api_call_bearer "api/2/tenants/${_partner_tenant_id}/offering_items" \
					"application/json" \
					"$(cat offering_items_to_put.json)" > /dev/null