#!/bin/bash

#**************************************************************************************************************
# Copyright © 2019-2020 Acronis International GmbH. This source code is distributed under MIT software license.
#**************************************************************************************************************

. 00.basis_functions.sh

. 01.basic_api_checks.sh

# Get Root tenant_id for the API Client
# Call a function to pipe JSON from file, extract JSON property, remove quotas from the property's value
_tenant_id=$(_get_tenant_id_from_file api_client.json)

# Construct JSON to create a report
_json='{
    "parameters": {
        "kind": "usage_current",
        "tenant_id": "'$_tenant_id'",
        "level": "accounts",
        "formats": [
            "csv_v2_0"
        ]
    },
    "schedule": {
        "type": "once"
    },
    "result_action": "save"
}'

# To create a report
# POST API call using function defined in basis_functions.sh
# with following parameters
# $1 - an API endpoint to call
# $2 - Content-Type
# $3 - POST data
# The result is stored in created_report.json file
_post_api_call_bearer "api/2/reports" \
					"application/json" \
					"${_json}" > created_report.json

# Get report_id from saved file
# Call a function to pipe JSON from file, extract JSON property, remove quotas from the property's value
_report_id=$(_get_id_from_file created_report.json)

# Init $_report_status to have at least 1 loop execution
_report_status="not saved"

# A report is not produced momently, so we need to wait for it to become saved
# Here is a simple implementation for sample purpose expecting that
# For sample purposes we use 1 report from stored -- as we use once report
while [[ $_report_status != "saved" ]] ; do

	# To get a saved report info
	# GET call using function defined in basis_functions.sh
	# with following parameters
	# $1 - an API endpoint to call
	# The result is stored in "${_report_id}_report.json" file
	_get_api_call_bearer "api/2/reports/${_report_id}/stored" \
					  > "${_report_id}_report_status.json"


	_report_status=$(jq '.items[0].status' < "${_report_id}_report_status.json" | sed -e 's/^"//' -e 's/"$//')

	sleep 2s
done

# For sample purposes we use 1 report from stored -- as we use once report
# MUST BE CHANGED if you want to deal with scheduled one or you have multiple reports
_stored_report_id=$(jq '.items[0].id' < "${_report_id}_report_status.json" | sed -e 's/^"//' -e 's/"$//')

# Download the report
# The result is stored in "${_report_id}_report.csv" file
# Response is gzip-ed so we need to add --compressed to have an output file decompressed
# _base_url is loaded from config file in 00.basis_functions.sh
curl	--compressed \
		-X GET \
		--url "${_base_url}api/2/reports/${_report_id}/stored/${_stored_report_id}" \
		-H "Authorization: Bearer ${_access_token}" \
		-o "${_report_id}_report.csv"
