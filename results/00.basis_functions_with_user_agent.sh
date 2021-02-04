#**************************************************************************************************************
# Copyright © 2019-2020 Acronis International GmbH. This source code is distributed under MIT software license.
#**************************************************************************************************************

# Treat unset variables as an error when substituting
set -u

# To exit from the main script when _die is called
shopt -s lastpipe

# Print errors info to STDERR and exit execution
_die() { printf ":: %s\n\n" "$*" >&2; exit 1; }

# Get a value for from config files
_config_get_value() {

	if test -f cyber.platform.cfg.json ; then
		_value=$(jq ."${1}" < cyber.platform.cfg.json | sed -e 's/^"//' -e 's/"$//')
		if [[ "$_value" = "null" ]]; then
			if test -f cyber.platform.cfg.defaults.json ; then
				_value=$(jq ."${1}" < cyber.platform.cfg.defaults.json | sed -e 's/^"//' -e 's/"$//')

				if [[ "$_value" = "null" ]]; then
					_die "A required value for ${1} doesn't exist in cyber.platform.cfg.json and cyber.platform.cfg.defaults.json files. Please add."
				fi

			else
				_die "A required value for ${1} doesn't exist in file cyber.platform.cfg.json. But the default configuration file cyber.platform.cfg.defaults.json doesn't exist."
			fi
	fi
	else
		_die "The file cyber.platform.cfg.json. Please create a config file."
	fi

	echo "${_value}"
}

# Load a config value
# Base URL for API request
_base_url=$(_config_get_value base_url)

# Call a function to pipe JSON from file, extract JSON property, remove quotas from the property's value
_access_token=$(_get_access_token_from_file api_token.json)

# By default we don't trace API Calls info
# trace set to 0 in cyber.platform.cfg.defaults.json
# But you can override it in cyber.platform.cfg.json
_config_trace=$(_config_get_value trace)

# Pipe JSON from file, extract JSON property, remove quotas from the property's value
_get_access_token_from_file(){ jq '.access_token' < "${1}" | sed -e 's/^"//' -e 's/"$//'; }

# Pipe JSON from file, extract JSON property, remove quotas from the property's value
_get_tenant_id_from_file(){ jq '.tenant_id' < "${1}" | sed -e 's/^"//' -e 's/"$//'; }

# Pipe JSON from file, extract JSON property, remove quotas from the property's value
_get_id_from_file(){ jq '.id' < "${1}" | sed -e 's/^"//' -e 's/"$//'; }

# Pipe JSON from file, extract JSON property, remove quotas from the property's value
_get_personal_tenant_id_from_file(){ jq '.personal_tenant_id' < "${1}" | sed -e 's/^"//' -e 's/"$//'; }

# Pipe JSON from file, extract JSON property, remove quotas from the property's value
_get_installation_token_from_file(){ jq '.token' < "${1}" | sed -e 's/^"//' -e 's/"$//'; }

# Implement API Call tracing capability
_call(){

	if [[ $_config_trace = 1 ]]; then
		printf "API call trace::\n%s\n\n" "$*" >&2
	fi

	"$@"
}

# Implement API Call responses tracing capability
_response(){

	if [[ $_config_trace = 1 ]]; then
		printf "API response trace::\n%s\n\n" "$*" >&2
	fi
}

# GET API call with Basic Authentication
# $1 - an API endpoint to call
# $2 - a login for Basic Authentication
# $3 - a password for Basic Authentication
_get_api_call_basic () {

  local _response_body
  local _response_code

  _call \
  curl	-s \
		-X GET \
		--url "${_base_url}$1" \
		-u "${2}:${3}" \
		-H "Accept: application/json" \
		-H "User-Agent: ACP 2.0/Acronis Cyber Platform Bash Examples" \
		-w "\n%{http_code}" | {
			read -r _response_body
			read -r _response_code

			_response "${_response_body}"

			if [[ $_response_code = 20* ]] ; then
  				echo "${_response_body}"
			else
				_die "The GET API Call with the endpoint ${1} is unsuccessful with response code: ${_response_code}." "${_response_body}"
			fi
		}
}

# GET API call with Bearer Authentication
# $1 - an API endpoint to call
_get_api_call_bearer () {

  local _response_body
  local _response_code

  _call \
  curl	-s \
		-X GET \
		--url "${_base_url}${1}" \
		-H "Authorization: Bearer ${_access_token}" \
		-H "Accept: application/json" \
		-H "User-Agent: ACP 2.0/Acronis Cyber Platform Bash Examples" \
		-w "\n%{http_code}" | {
			read -r _response_body
			read -r _response_code

			_response "${_response_body}"

			if [[ $_response_code = 20* ]] ; then
  				echo "${_response_body}"
			else
				_die  "The GET API Call with the endpoint ${1} is unsuccessful with response code: ${_response_code}." "${_response_body}"
			fi
		}
}

# GET API call with Bearer Authentication
# $1 - an API endpoint to call
_get_api_call_bearer_alerts () {

  local _response_body
  local _response_body_end
  local _response_code

  _call \
  curl	-s \
		-X GET \
		--url "${_base_url}${1}" \
		-H "Authorization: Bearer ${_access_token}" \
		-H "Accept: application/json" \
		-H "User-Agent: ACP 2.0/Acronis Cyber Platform Bash Examples" \
		-w "\n%{http_code}" | {
			read -r _response_body
			read -r _response_body_end
			read -r _response_code

			_response "${_response_body}${_response_body_end}"

			if [[ $_response_code = 20* ]] ; then
  				echo "${_response_body}${_response_body_end}"
			else
				_die  "The GET API Call with the endpoint ${1} is unsuccessful with response code: ${_response_code}." "${_response_body}"
			fi
		}
}

# GET API call with Bearer Authentication
# $1 - an API endpoint to call
_get_api_call_bearer_with_response_code () {

  local _response_body
  local _response_code

  _call \
  curl	-s \
		-X GET \
		--url "${_base_url}${1}" \
		-H "Authorization: Bearer ${_access_token}" \
		-H "Accept: application/json" \
		-H "User-Agent: ACP 2.0/Acronis Cyber Platform Bash Examples" \
		-w "\n%{http_code}" | {
			read -r _response_body
			read -r _response_code

			_response "${_response_body}"

			if [[ $_response_code = 20* ]] ; then
  				printf "%s\n%s" "${_response_code}" "${_response_body}"
			else
				_die  "The GET API Call with the endpoint ${1} is unsuccessful with response code: ${_response_code}." "${_response_body}"
			fi
		}
}

# POST API call with Basic Authentication
# $1 - an API endpoint to call
# $2 - a login for Basic Authentication
# $3 - a password for Basic Authentication
# $4 - POST data
# $5 - Content-Type
_post_api_call_basic () {

  local _response_body
  local _response_code

 _call \
 curl	-s \
		-X POST \
		--url "${_base_url}${1}" \
		-u "${2}:${3}" \
		-H "Accept: application/json" \
		-H "User-Agent: ACP 2.0/Acronis Cyber Platform Bash Examples" \
		-H "Content-type: $5" \
		--data-raw "$4" \
		-w "\n%{http_code}" | {
			read -r _response_body
			read -r _response_code

			_response "${_response_body}"

			if [[ $_response_code = 20* ]] ; then
  				echo "${_response_body}"
			else
				_die "The POST API Call with the endpoint ${1} is unsuccessful with response code: ${_response_code}." "${_response_body}"
			fi
		}
}

# POST API call with Bearer Authentication
# $1 - an API endpoint to call
# $2 - Content-Type
# $3 - POST data
_post_api_call_bearer () {

  local _response_body
  local _response_code

  _call \
  curl	-s \
		-X POST \
		--url "${_base_url}${1}" \
		-H "Authorization: Bearer _access_token" \
		-H "Accept: application/json" \
		-H "User-Agent: ACP 2.0/Acronis Cyber Platform Bash Examples" \
		-H "Content-type: ${2}" \
		--data-raw "${3}" \
		-w "\n%{http_code}" | {
			read -r _response_body
			read -r _response_code

			_response "${_response_body}"

			if [[ $_response_code = 20* ]] ; then
  				echo "${_response_body}"
			else
				_die "The POST API Call with the endpoint ${1} is unsuccessful with response code: ${_response_code}." "${_response_body}"
			fi
		}
}

# POST API call with Bearer Authentication for Backup Console requests
# To handle addition CR in JSON response
# $1 - an API endpoint to call
# $2 - Content-Type
# $3 - POST data
_post_api_call_bearer_bc () {

  local _response_body
  local _response_body_end
  local _response_code

  _call \
  curl	-s \
		-X POST \
		--url "${_base_url}${1}" \
		-H "Authorization: Bearer ${_access_token}" \
		-H "Accept: application/json" \
		-H "User-Agent: ACP 2.0/Acronis Cyber Platform Bash Examples" \
		-H "Content-type: ${2}" \
		--data-raw "${4}" \
		-w "\n%{http_code}" | {
			read -r _response_body
			read -r _response_body_end
			read -r _response_code

			_response "${_response_body}${_response_body_end}"

			if [[ $_response_code = 20* ]] ; then
  				echo "${_response_body}${_response_body_end}"
			else
				_die "The POST API Call with the endpoint ${1} is unsuccessful with response code: ${_response_code}." "${_response_body}${_response_body_end}"
			fi
		}
}

# PUT API call with Bearer Authentication
# $1 - an API endpoint to call
# $2 - Content-Type
# $3 - POST data
_put_api_call_bearer () {

  local _response_body
  local _response_code

  _call \
  curl	-s \
		-X PUT \
		--url "${_base_url}${1}" \
		-H "Authorization: Bearer ${_access_token}" \
		-H "Accept: application/json" \
		-H "User-Agent: ACP 2.0/Acronis Cyber Platform Bash Examples" \
		-H "Content-type: ${2}" \
		--data-raw "${3}" \
		-w "\n%{http_code}" | {
			read -r _response_body
			read -r _response_code

			_response "${_response_body}"

			if [[ $_response_code = 20* ]] ; then
  				echo "${_response_body}"
			else
				_die "The PUT API Call with the endpoint ${1} is unsuccessful with response code: ${_response_code}." "${_response_body}"
			fi
		}
}

# Issue an authorization token
# Expect that an API client information are stored
# in native API output format in api_client.json file
# $1 - base URL
_issue_token() {

		local _client_id
		local _client_secret

		# Pipe JSON from file, extract JSON property, remove trilling quotas from the property's value
		_client_id=$(jq '.client_id' < api_client.json | sed -e 's/^"//' -e 's/"$//')
		_client_secret=$(jq '.client_secret' < api_client.json | sed -e 's/^"//' -e 's/"$//')

		# POST call to issue an authorization token
		# To use it you need have the following parameters passed
		# $1 - an API endpoint to call
		# $2 - a login for Basic Authentication
		# $3 - a password for Basic Authentication
		# $3 - POST data
		# $5 - Content-Type
		_post_api_call_basic "api/2/idp/token" \
							"${_client_id}" "${_client_secret}" \
							"grant_type=client_credentials" \
							"application/x-www-form-urlencoded" > api_token.json
}


# Check if an authorization token in valid next 15 minutes (900 sec)
# And if it's not, a new token will be issued
# Expect that an authorization token information are stored
# in native API output format in api_token.json file
# Still works correctly if you didn't have a token file
_renew_token_if_needed() {

	local _expires_on
	local _current_unix_time
	local _time_left

	if test -f api_token.json; then
		# Pipe JSON from file, extract JSON property
		_expires_on=$(jq '.expires_on' < api_token.json)
		_current_unix_time=$(date +%s)
		_time_left=$_expires_on-$_current_unix_time
		if [[ $_time_left -le 900 ]] ; then
			_issue_token
		fi
	else
		_issue_token
	fi
}