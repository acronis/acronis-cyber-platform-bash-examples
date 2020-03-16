#!/bin/bash

#**************************************************************************************************************
# Copyright © 2019-2020 Acronis International GmbH. This source code is distributed under MIT software license.
#**************************************************************************************************************

. 00.basis_functions.sh

. 01.basic_api_checks.sh

# Call a function to pipe JSON from file, extract JSON property, remove quotas from the property's value
_access_token=$(_get_access_token_from_file api_token.json)

# Call a function to pipe JSON from file, extract JSON property
_tenant_id=$(_get_id_from_file partner.json)

# Construct JSON to request a customer tenant creation
_json='{
		"name": "MyBashCustomer",
		"parent_id": "'$_tenant_id'",
		"kind": "customer"
	}'

# To create a customer tenant
# POST API call using function defined in basis_functions.sh
# with following parameters
# $1 - an API endpoint to call
# $2 - a bearer token Bearer Authentication
# $3 - Content-Type
# $4 - POST data
# The result is stored in customer.json file
_post_api_call_bearer "api/2/tenants" \
					"${_access_token}" \
					"application/json" \
					"${_json}" > customer.json

# Get Kind of tenant from config file
_kind=$(_config_get_value customer_tenant)

# Get Edition we plan to enable from config file
_edition=$(_config_get_value edition)

# To get a list of offering ite,s available for a child tenant
# GET call using function defined in basis_functions.sh
# with following parameters
# $1 - an API endpoint to call
# $2 - a bearer token Bearer Authentication
# The result is stored in offering_items_available_for_customer_child.json file
_get_api_call_bearer "api/2/tenants/${_tenant_id}/offering_items/available_for_child?kind=${_kind}&edition=${_edition}" \
					"${_access_token}" > offering_items_available_for_customer_child.json

# Replace "items" with "offering_items" as the following API call expects to have it as a root JSON element
sed 's/"items"/"offering_items"/g' < offering_items_available_for_customer_child.json > customer_offering_items_to_put.json


# Call a function to pipe JSON from file, extract JSON property
_customer_tenant_id=$(_get_id_from_file customer.json)

# To update offering item for a tenant
# PUT API call using function defined in basis_functions.sh
# with following parameters
# $1 - an API endpoint to call
# $2 - a bearer token Bearer Authentication
# $3 - Content-Type
# $4 - PUT data
_put_api_call_bearer "api/2/tenants/${_customer_tenant_id}/offering_items" \
					"${_access_token}" \
					"application/json" \
					"$(cat customer_offering_items_to_put.json)" > /dev/null

# By default, a customer tenant is created in Trial mode
# To Switching customer tenant to production mode
# The pricing mode should be changed from trial to production

# To get a current pricing for a customer tenant
# GET call using function defined in basis_functions.sh
# with following parameters
# $1 - an API endpoint to call
# $2 - a bearer token Bearer Authentication
# The result is stored in customer_tenant_pricing.json file
_get_api_call_bearer "api/2/tenants/${_customer_tenant_id}/pricing" \
					"${_access_token}" > customer_tenant_pricing.json

# Replace "trial" with "production" to have a JSON needed to switch the customer tenant to production mode
# NOTE: THIS CHANGE IS IRREVERSIBLE
sed 's/"trial"/"production"/g' < customer_tenant_pricing.json > customer_tenant_pricing_to_put.json

# Switching customer tenant to production mode
# By updating pricing for a tenant
# PUT API call using function defined in basis_functions.sh
# with following parameters
# $1 - an API endpoint to call
# $2 - a bearer token Bearer Authentication
# $3 - Content-Type
# $4 - PUT data
_put_api_call_bearer "api/2/tenants/${_customer_tenant_id}/pricing" \
					"${_access_token}" \
					"application/json" \
					"$(cat customer_tenant_pricing_to_put.json)" > /dev/null