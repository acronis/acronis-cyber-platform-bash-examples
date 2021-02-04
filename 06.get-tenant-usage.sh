#!/bin/bash

#**************************************************************************************************************
# Copyright © 2019-2020 Acronis International GmbH. This source code is distributed under MIT software license.
#**************************************************************************************************************

. 00.basis_functions.sh

. 01.basic_api_checks.sh

# Get Root tenant_id for the API Client
# Pipe JSON from file, extract JSON property, remove quotas from the property's value
_tenant_id=$(_get_tenant_id_from_file api_client.json)

# To get a tenant usage
# GET call using function defined in basis_functions.sh
# with following parameters
# $1 - an API endpoint to call
# The result is stored in "${_tenant_id}_usage.json" file
_get_api_call_bearer "api/2/tenants/${_tenant_id}/usages" \
					  > "${_tenant_id}_usage.json"