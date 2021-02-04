#!/bin/bash

#**************************************************************************************************************
# Copyright © 2019-2020 Acronis International GmbH. This source code is distributed under MIT software license.
#**************************************************************************************************************

. 00.basis_functions.sh

. 01.basic_api_checks.sh

# Call a function to pipe JSON from file, extract JSON property
_customer_tenant_id=$(_get_id_from_file customer.json)

# Retrieve int tenant id by uuid tenant id
# GET API call with Bearer Authentication
# $1 - an API endpoint to call
_customer_tenant_int_id=$(_get_api_call_bearer "api/1/groups/${_customer_tenant_id}" \
											| jq '.id' | sed -e 's/^"//' -e 's/"$//')


# Get list of all Acronis Agents for tenants subtree
# where the root tenant is
# a previously created customer
# GET API call with Bearer Authentication
# $1 - an API endpoint to call

_get_api_call_bearer "api/agent_manager/v2/agents?tenant_id=${_customer_tenant_int_id}" \
					 > all_agents_for_customer.json