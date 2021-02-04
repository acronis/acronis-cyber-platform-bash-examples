#!/bin/bash

#**************************************************************************************************************
# Copyright © 2019-2020 Acronis International GmbH. This source code is distributed under MIT software license.
#**************************************************************************************************************

. 00.basis_functions.sh

. 01.basic_api_checks.sh

# Create an acceptable date for alerts filtering
_last_week=$(date --date="-7 days" +%Y-%m-%dT00:00:00Z)
_last_week=$(date -d "${_last_week}" +%s)
_last_week="${_last_week}000000000"

# Get list of all alerts updated during last 7 days for all subtenants
# of the tenant for which the API Client was issue
# Special version of _get function to workaround /n in JSON output
# GET API call with Bearer Authentication
# $1 - an API endpoint to call
_get_api_call_bearer_alerts "api/alert_manager/v1/alerts?updated_at=gt(${_last_week})&order=desc(created_at)" \
					 > all_alerts_for_the_last_week.json