#!/bin/bash

#**************************************************************************************************************
# Copyright © 2019-2020 Acronis International GmbH. This source code is distributed under MIT software license.
#**************************************************************************************************************

. 00.basis_functions.sh

. 01.basic_api_checks.sh

# Call a function to pipe JSON from file, extract JSON property
_tenant_id=$(_get_id_from_file partner.json)

# Construct JSON to request a customer tenant creation
_json='{
		"name": "MyBashCustomer14",
		"parent_id": "'$_tenant_id'",
		"kind": "customer"
	}'

# To create a customer tenant
# POST API call using function defined in basis_functions.sh
# with following parameters
# $1 - an API endpoint to call
# $2 - Content-Type
# $3 - POST data
# The result is stored in customer.json file
_post_api_call_bearer "api/2/tenants" \
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

# The result is stored in offering_items_available_for_customer_child.json file
_get_api_call_bearer "api/2/tenants/${_tenant_id}/offering_items/available_for_child?kind=${_kind}&edition=${_edition}" \
					> offering_items_available_for_customer_child.json

# Replace "items" with "offering_items" as the following API call expects to have it as a root JSON element
sed 's/"items"/"offering_items"/g' < offering_items_available_for_customer_child.json > customer_offering_items_to_put.json

# Check how many unique infrastructures and what types we have in full offering item list
_infra_uuids=$(jq '[.offering_items[] | .infra_id | strings] | unique | join(",")' customer_offering_items_to_put.json | sed -e 's/^"//' -e 's/"$//')

_get_api_call_bearer "api/2/infra?uuids=${_infra_uuids}" > infrastructures.json

# Select capabilities from infrastructure.json
# Then build an grouped array to calculate count of unique capabilities
# Convert it back to stream
# Select only capabilities which have count > 1
# Save to capabilities.json file
jq '[[.items[] | .capabilities | .[] | values ]
    | map({infra_type: .})
	| group_by(.infra_type)
	| map({infra_type: .[0].infra_type, count: length})
	| .[]
	|  select(.count>1)]' infrastructures.json > capabilities.json

# For demo purposes
# We just filter out first infrastructure (storage) with the same capability
# You need to implement your logic
jq -c '.[].infra_type' capabilities.json | sed -e 's/^"//' -e 's/"$//' | while read _infra_type; do
  _infra_uuid=$(jq "[.items[] | select(.capabilities[] | contains(\"$_infra_type\"))]| .[1].id" infrastructures.json | sed -e 's/^"//' -e 's/"$//')
  jq "del( .offering_items[] | select(.infra_id == \"$_infra_uuid\"))" customer_offering_items_to_put.json > customer_offering_items_to_put_tempo.json
  mv -f customer_offering_items_to_put_tempo.json customer_offering_items_to_put.json
done

# Call a function to pipe JSON from file, extract JSON property
_customer_tenant_id=$(_get_id_from_file customer.json)

# To update offering item for a tenant
# PUT API call using function defined in basis_functions.sh
# with following parameters
# $1 - an API endpoint to call
# $2 - Content-Type
# $4 - PUT data
_put_api_call_bearer "api/2/tenants/${_customer_tenant_id}/offering_items" \
					"application/json" \
					"$(cat customer_offering_items_to_put.json)" > /dev/null

# By default, a customer tenant is created in Trial mode
# To Switching customer tenant to production mode
# The pricing mode should be changed from trial to production

# To get a current pricing for a customer tenant
# GET call using function defined in basis_functions.sh
# with following parameters
# $1 - an API endpoint to call
# The result is stored in customer_tenant_pricing.json file
_get_api_call_bearer "api/2/tenants/${_customer_tenant_id}/pricing" \
					 > customer_tenant_pricing.json

# Replace "trial" with "production" to have a JSON needed to switch the customer tenant to production mode
# NOTE: THIS CHANGE IS IRREVERSIBLE
sed 's/"trial"/"production"/g' < customer_tenant_pricing.json > customer_tenant_pricing_to_put.json

# Switching customer tenant to production mode
# By updating pricing for a tenant
# PUT API call using function defined in basis_functions.sh
# with following parameters
# $1 - an API endpoint to call
# $2 - Content-Type
# $4 - PUT data
_put_api_call_bearer "api/2/tenants/${_customer_tenant_id}/pricing" \
					"application/json" \
					"$(cat customer_tenant_pricing_to_put.json)" > /dev/null