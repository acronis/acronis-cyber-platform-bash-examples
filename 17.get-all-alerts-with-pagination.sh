#!/bin/bash

#**************************************************************************************************************
# Copyright © 2019-2020 Acronis International GmbH. This source code is distributed under MIT software license.
#**************************************************************************************************************

. 00.basis_functions.sh

. 01.basic_api_checks.sh

# Page size
_page_size=10

# Get list of all alerts for all subtenants
# of the tenant for which the API Client was issue
# using pagination retrieve a cursor pointer to make the next request
# GET API call with Bearer Authentication
# $1 - an API endpoint to call
_cursor=$(_get_api_call_bearer_alerts "api/alert_manager/v1/alerts?limit=${_page_size}" \
					| jq '.paging.cursors.after' | sed -e 's/^"//' -e 's/"$//')

_page_number=1


while [ -n "${_cursor}" ] && [ "${_cursor}" != "null" ]; do
echo "The page number ${_page_number}"

# Get list of all alerts for all subtenants
# of the tenant for which the API Client was issue
# using pagination and retrieve a cursor pointer to make the next request
# GET API call with Bearer Authentication
# $1 - an API endpoint to call

_get_api_call_bearer_alerts "api/alert_manager/v1/alerts?limit=${_page_size}&after=${_cursor}" \
					> alerts_current_page.json

_cursor=$(jq '.paging.cursors.after' < alerts_current_page.json | sed -e 's/^"//' -e 's/"$//')

_page_number=$((_page_number+1))
done

echo "The alerts were paged to the end."

_cursor=$(jq '.paging.cursors.before' < alerts_current_page.json | sed -e 's/^"//' -e 's/"$//')

_page_number=$((_page_number-2))

while [ -n "${_cursor}" ] && [ "${_cursor}" != "null" ]; do
echo "The page number ${_page_number}"

# Get list of all alerts for all subtenants
# of the tenant for which the API Client was issue
# using pagination and retrieve a cursor pointer to make the next request
# GET API call with Bearer Authentication
# $1 - an API endpoint to call

_get_api_call_bearer_alerts "api/alert_manager/v1/alerts?limit=${_page_size}&before=${_cursor}" \
					 > alerts_current_page.json

_cursor=$(jq '.paging.cursors.before' < alerts_current_page.json | sed -e 's/^"//' -e 's/"$//')

_page_number=$((_page_number-1))

done

echo "The alerts were paged to the start."
