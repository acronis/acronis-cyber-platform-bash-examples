#!/bin/bash

#**************************************************************************************************************
# Copyright © 2019-2020 Acronis International GmbH. This source code is distributed under MIT software license.
#**************************************************************************************************************

. 00.basis_functions.sh

. 01.basic_api_checks.sh

# GET API call with Bearer Authentication
# $1 - an API endpoint to call
_get_api_call_bearer 'api/agent_manager/v2/agents' \
					 > all_agents.json