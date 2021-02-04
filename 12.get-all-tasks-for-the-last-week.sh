#!/bin/bash

#**************************************************************************************************************
# Copyright © 2019-2020 Acronis International GmbH. This source code is distributed under MIT software license.
#**************************************************************************************************************

. 00.basis_functions.sh

. 01.basic_api_checks.sh


# Create an acceptable date for tasks filtering
_last_week=$(date --date="-7 days" +%Y-%m-%dT00:00:00Z)

# Get list of all tasks completed during last 7 days for all subtenants
# of the tenant for which the API Client was issue
# GET API call with Bearer Authentication
# $1 - an API endpoint to call
_get_api_call_bearer "api/task_manager/v2/tasks?completedAt=gt(${_last_week})" \
					> all_task_for_the_last_week.json