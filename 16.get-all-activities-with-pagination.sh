#!/bin/bash

#**************************************************************************************************************
# Copyright © 2019-2020 Acronis International GmbH. This source code is distributed under MIT software license.
#**************************************************************************************************************

. 00.basis_functions.sh

. 01.basic_api_checks.sh

# Page size
_page_size=10

# Get list of all activities for all subtenants
# of the tenant for which the API Client was issue
# using pagination retrieve a cursor pointer to make the next request
# GET API call with Bearer Authentication
# $1 - an API endpoint to call
_after_cursor=$(_get_api_call_bearer "api/task_manager/v2/activities?limit=${_page_size}" \
					 | jq '.paging.cursors.after' | sed -e 's/^"//' -e 's/"$//')

_page_number=1


while [ -n "${_after_cursor}" ] && [ "${_after_cursor}" != "null" ]; do
echo "The page number ${_page_number}"

# Get list of all activities for all subtenants
# of the tenant for which the API Client was issue
# using pagination and retrieve a cursor pointer to make the next request
# GET API call with Bearer Authentication
# $1 - an API endpoint to call

_after_cursor=$(_get_api_call_bearer "api/task_manager/v2/activities?limit=${_page_size}&after=${_after_cursor}" \
					 | jq '.paging.cursors.after' | sed -e 's/^"//' -e 's/"$//')

_page_number=$((_page_number+1))
done

echo "The activities were paged to the end."
