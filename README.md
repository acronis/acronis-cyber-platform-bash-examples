# Base Acronis Cyber Platform API operations with bash

Bash is a very powerful tool which is suitable for many management tasks. It’s particularly popular for managing Linux workloads. So, let's look deeply at how to use bash to solve common tasks with the Acronis Cyber Platform API.

## Prerequisites and basis information

To access the API we use `curl` utility, to process JSON, we use `jq` utility. So, please, be sure that you have `curl` and `jq` available.

To simplify code basis functions to call the API have created: `_get_api_call_basic`,
`_get_api_call_bearer`, `_get_api_call_bearer_with_response_code`, `_post_api_call_basic`, `_post_api_call_bearer` and `_put_api_call_bearer` as well as other utility functions.

You can find descriptions and code at the end of the article.

To run the scripts, you need to edit or create the `cyber.platform.cfg.json` file to provide base parameters. At minimum you need to change `base_url` to your data center URL. The global variables `_base_url` initialized from the config file and used for all API requests. All other values can remain unchanged.
A `cyber.platform.cfg.json` file example:

```json
{
 	"base_url": "https://dev-cloud.acronis.com/",
	"partner_tenant": "partner",
	"customer_tenant": "customer",
	"edition": "standard"
}
```

The API Call trace functionality is also available. By default, API calls are not traced as `trace` set to 0 in `cyber.platform.cfg.defaults.json` file, which you might create, but you can override it in `cyber.platform.cfg.json` file if you need it. As soon as its enabled you will see in `STDERR` `curl` API calls with all parameters as well as a raw response form the calls.

A `cyber.platform.cfg.defaults.json` file example:

```json
{
 	"base_url": "https://dev-cloud.acronis.com/",
	"partner_tenant": "partner",
	"customer_tenant": "customer",
	"edition": "standard",
	"trace": 0
}
```

## Create an API Client to access the API

A JWT token with a limited time to life approach is used to securely manage access of any API clients, like our scripts, for the Acronis Cyber Cloud. Using a login and password for a specific user is not a secure and manageable way to create a token, but technically it's possible. Thus, we create an API client with a client id and a client secret to use as credentials to issue a JWT token.
To create an API Client, we call the `/clients` end-point with POST request specifying in the JSON body of the request a tenant we want to have access to. To authorize this the request, the Basic Authorization with user login and password for Acronis Cyber Cloud is used.
***
NOTE: In Acronis Cyber Cloud 9.0 API Client credentials can be generated in the Management Portal.
***
NOTE: Normally, creating an API Client is a one-time process. As the API client is used to access the API, treat it as credentials and store securely. Also, do not store the login and password in the scripts itself.
***
In the following code block a login and a password are requested from a command line and use it for a Basic Authorization for following HTTP requests.

```bash
# Ask the user for login details
# To use for Basic Authentication
# To create an API Client
printf "\n"
read -rp 'Login: ' _login
read -rsp 'Password: ' _password
printf "\n\n"
```

In those scripts it is expected that the [Acronis Developer Sandbox](https://developer.acronis.com/sandbox/) is used. It is available for registered developers at [Acronis Developer Network Portal](https://developer.acronis.com/). So the base URL for all requests (https://devcloud.acronis.com/) is used. Please, replace it with correct URL for your production environment if needed. For more details, please, review the [Authenticating to the platform via the Python shell tutorial](https://developer.acronis.com/doc/platform/management/v2/#/http/developer-s-guide/authenticating-to-the-platform-via-the-python-shell) from the Acronis Cyber Platform documentation.

For demo purposes, this script issues an API client for a tenant for a user for whom a login and a password are specified. You should add your logic as to what tenant should be used for the API Client creation.

```bash
# Request self-ifo from API using Basic Authentication
# GET call using function defined in basis_functions.sh
# with following parameters
# $1 - an API endpoint to call
# $2 - a login for Basic Authentication
# $3 - a password for Basic Authentication
# The result is going to jq utility to extract JSON property
# Please NOTE, that this property is retrieved with quotas
_tenant_id=$(_get_api_call_basic "api/2/users/me" "${_login}" "${_password}" | jq '.tenant_id')

# Construct JSON to request an API Client creation
_json='{
		"type": "agent",
		"tenant_id": '$_tenant_id',
		"token_endpoint_auth_method": "client_secret_basic",
		"data": {
				"name": "bash.App"
				}
	  }'

# To create an API Client
# GET call using function defined in basis_functions.sh
# with following parameters
# $1 - an API endpoint to call
# $2 - a login for Basic Authentication
# $3 - a password for Basic Authentication
# The result is stored in api_client.json file
_post_api_call_basic "api/2/clients" \
					"${_login}" "${_password}" \
					"${_json}" \
					"application/json" > api_client.json
```

You need to securely store the received credentials. For simplicity of the demo code, a simple JSON format is used for `api_client.json` file. Please remember to implement secure storage for your client credentials.

## Issue a token to access the API

A `client_id` and a `client_secret` can be used to access the API using the Basic Authorization but it's not a secure way as we discussed above. It's more secure to have a JWT token with limited life-time and implement a renew/refresh logic for that token.

To issue a token `/idp/token` end-point is called using `POST` request with param `grant_type` equal `client_credentials` and content type `application/x-www-form-urlencoded` with Basic Authorization using a `client_id` as a user name and a `client_secret` as a password.

```bash
# Pipe JSON from file, extract JSON property, remove quotas from the property's value
_client_id=$(jq '.client_id' < api_client.json | sed -e 's/^"//' -e 's/"$//')
_client_secret=$(jq '.client_secret' < api_client.json | sed -e 's/^"//' -e 's/"$//')

# To issue a token
# POST call using function defined in basis_functions.sh
# with following parameters
# $1 - an API endpoint to call
# $2 - a login for Basic Authentication
# $3 - a password for Basic Authentication
# $4 - POST data
# $5 - Content-Type
# The result is stored in api_token.json file
_post_api_call_basic "api/2/idp/token" \
					"${_client_id}" "${_client_secret}" \
					"grant_type=client_credentials" \
					"application/x-www-form-urlencoded" > api_token.json
```

You need to securely store the received token. For simplicity of the demo code, the received JSON format is used `api_token.json` file. Please implement secure storage for your tokens.

A token has time-to-live and must be renewed/refreshed before expiration time. The best practice is to check before starting any API calls sequence and renew/refresh if needed. Assuming that the token is stored in the JSON response format as above, it can be done using the following functions set.

`expires_on` is a time when the token will expire in Unix time format -- seconds from January 1, 1970. Here we assume that we will renew/refresh a token 15 minutes before the expiration time.


```bash
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
		# $4 - POST data
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
```

## Create partner, customer and user tenants and set offering items

So now we can securely access the Acronis Cyber Platform API calls. In this topic we discuss how to create a partner, a customer tenants and enable for them all available offering items, and then create a user for the customer and activate the user by setting a password.

As we discussed above, before making a call to the actual API you need to ensure that an authorization token is valid. Please, use the functions like those described above to do it.

Assuming that we create the API client for our root tenant, we start from retrieving the API Client tenant information using GET request to `/clients/${_client_id}` end-point. Then, using received `tenant_id` information as a parameter and `kind` equal to `partner`, we build a JSON body for POST request to `/tenants` end-point to create the partner. Next, we are going to enable all applications and offering items for the tenants.  Briefly, we take all available offering items for the parent tenant of the partner or the customer using
GET request to `/tenants/${_tenant_id}/offering_items/available_for_child` end-point with needed query parameters specifying `edition` and `kind` of the tenant. Then, we need to enable these offering items for the partner or the customer using PUT request to `/tenants/${_tenant_id}/offering_items` end-point with all offering items JSON in the request body and appropriate `_tenant_id`.

***
NOTE: The following `kind` values are supported `root`, `partner`, `folder`, `customer`, `unit`.
***

```bash
# Call a function to pipe JSON from file, extract JSON property, remove quotas from the property's value
_access_token=$(_get_access_token_from_file api_token.json)

# Call a function to pipe JSON from file, extract JSON property
_tenant_id=$(_get_tenant_id_from_file api_client.json)

# Construct JSON to request a partner tenant creation
_json='{
		"name": "MyBashPartner",
		"parent_id": "'$_tenant_id'",
		"kind": "partner"
	}'

# To create a partner tenant
# POST API call using function defined in basis_functions.sh
# with following parameters
# $1 - an API endpoint to call
# $2 - a bearer token Bearer Authentication
# $3 - Content-Type
# $4 - POST data
# The result is stored in partner.json file
_post_api_call_bearer "api/2/tenants" \
					"${_access_token}" \
					"application/json" \
					"${_json}" > partner.json

# Get Kind of a tenant from config file
_kind=$(_config_get_value partner_tenant)

# Get Edition we plan to enable from config file
_edition=$(_config_get_value edition)

# To get a list of offering ite,s available for a child tenant
# GET call using function defined in basis_functions.sh
# with following parameters
# $1 - an API endpoint to call
# $2 - a bearer token Bearer Authentication
# The result is stored in offering_items_available_for_child.json file
_get_api_call_bearer "api/2/tenants/${_tenant_id}/offering_items/available_for_child?kind=${_kind}&edition=${_edition}" \
					"${_access_token}" > offering_items_available_for_child.json


# Replace "items" with "offering_items" as the following API call expects to have it as a root JSON element
 sed 's/"items"/"offering_items"/g' < offering_items_available_for_child.json > offering_items_to_put.json


# Call a function to pipe JSON from file, extract JSON property
_partner_tenant_id=$(_get_id_from_file partner.json)

# To update offering item for a tenant
# PUT API call using function defined in basis_functions.sh
# with following parameters
# $1 - an API endpoint to call
# $2 - a bearer token Bearer Authentication
# $3 - Content-Type
# $4 - PUT data
_put_api_call_bearer "api/2/tenants/${_partner_tenant_id}/offering_items" \
					"${_access_token}" \
					"application/json" \
					"$(cat offering_items_to_put.json)" > /dev/null
```

This is absolutely the same process as for a customer, the only difference is `kind` equal to `customer` in the request body JSON and `/offering_items/available_for_child` parameters.

```bash
# Call a function to pipe JSON from file, extract JSON property, remove quotas from the property's value
_access_token=$(_get_access_token_from_file api_token.json)

# Call a function to pipe JSON from file, extract JSON property
_tenant_id=$(_get_id_from_file partner.json)

# Construct JSON to request a customer tenant creation
_json='{
		"name": "MyBashCustomer",
		"parent_id": "'$_tenant_id'",
		"kind": "customer"
	}'

# To create a customer tenant
# POST API call using function defined in basis_functions.sh
# with following parameters
# $1 - an API endpoint to call
# $2 - a bearer token Bearer Authentication
# $3 - Content-Type
# $4 - POST data
# The result is stored in customer.json file
_post_api_call_bearer "api/2/tenants" \
					"${_access_token}" \
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
# $2 - a bearer token Bearer Authentication
# The result is stored in offering_items_available_for_customer_child.json file
_get_api_call_bearer "api/2/tenants/${_tenant_id}/offering_items/available_for_child?kind=${_kind}&edition=${_edition}" \
					"${_access_token}" > offering_items_available_for_customer_child.json

# Replace "items" with "offering_items" as the following API call expects to have it as a root JSON element
sed 's/"items"/"offering_items"/g' < offering_items_available_for_customer_child.json > customer_offering_items_to_put.json


# Call a function to pipe JSON from file, extract JSON property
_customer_tenant_id=$(_get_id_from_file customer.json)

# To update offering item for a tenant
# PUT API call using function defined in basis_functions.sh
# with following parameters
# $1 - an API endpoint to call
# $2 - a bearer token Bearer Authentication
# $3 - Content-Type
# $4 - PUT data
_put_api_call_bearer "api/2/tenants/${_customer_tenant_id}/offering_items" \
					"${_access_token}" \
					"application/json" \
					"$(cat customer_offering_items_to_put.json)" > /dev/null
```

By default, customers are created in a trial mode. To switch to production mode we need to update customer pricing. To perform this task, we start from requesting current pricing using a GET request to
`/tenants/${_customer_tenant_id}/pricing` end-point then change `mode` property to `production` in the received JSON, then, finally, update the pricing using PUT request to `/tenants/${_customer_tenant_id}/pricing` end-point with a new pricing JSON.

***
NOTE: Please, be aware, that this switch is non-revertible.
***

```bash
# By default, a customer tenant is created in Trial mode
# To Switching customer tenant to production mode
# The pricing mode should be changed from trial to production

# To get a current pricing for a customer tenant
# GET call using function defined in basis_functions.sh
# with following parameters
# $1 - an API endpoint to call
# $2 - a bearer token Bearer Authentication
# The result is stored in customer_tenant_pricing.json file
_get_api_call_bearer "api/2/tenants/${_customer_tenant_id}/pricing" \
					"${_access_token}" > customer_tenant_pricing.json

# Replace "trial" with "production" to have a JSON needed to switch the customer tenant to production mode
# NOTE: THIS CHANGE IS IRREVERSIBLE
sed 's/"trial"/"production"/g' < customer_tenant_pricing.json > customer_tenant_pricing_to_put.json

# Switching customer tenant to production mode
# By updating pricing for a tenant
# PUT API call using function defined in basis_functions.sh
# with following parameters
# $1 - an API endpoint to call
# $2 - a bearer token Bearer Authentication
# $3 - Content-Type
# $4 - PUT data
_put_api_call_bearer "api/2/tenants/${_customer_tenant_id}/pricing" \
					"${_access_token}" \
					"application/json" \
					"$(cat customer_tenant_pricing_to_put.json)" > /dev/null
```

Finally, we create a user for the customer. At first, we check if a login is available using GET request to `/users/check_login` end-point with `username` parameter set to an expected login. Then, we create a JSON body for POST request to `/users` end-point to create a new user.

```bash
# Call a function to pipe JSON from file, extract JSON property, remove quotas from the property's value
_access_token=$(_get_access_token_from_file api_token.json)

# Set response code to 400 -- login availability check failed
_response_code=400

# Ask for proposed username
printf "\n"
read -rp 'Username: ' _username
printf "\n\n"

# To get an availability status of a username
# GET call using function defined in basis_functions.sh
# with following parameters
# $1 - an API endpoint to call
# $2 - a bearer token Bearer Authentication
_get_api_call_bearer_with_response_code "api/2/users/check_login?username=${_username}" \
										"${_access_token}" | {
											read -r _response_code
											read -r # here we would read the response body if need it
											if [[ $_response_code != 204 ]] ; then
  												_die  "The username ${_username} is already exists."
											fi
										}

# Here we can be only if _username is available

# Call a function to pipe JSON from file, extract JSON property
_customer_tenant_id=$(_get_id_from_file customer.json)


# Construct JSON to request a user creation
_json='{
		"tenant_id": "'$_customer_tenant_id'",
		"login": "'${_username}'",
		"contact": {
      				"email": "'${_username}'@example.com",
      				"firstname": "Bash",
      				"lastname": "Example"
					}
	  }'

# To create a user
# POST API call using function defined in basis_functions.sh
# with following parameters
# $1 - an API endpoint to call
# $2 - a bearer token Bearer Authentication
# $3 - Content-Type
# $4 - POST data
# The result is stored in user.json file
_post_api_call_bearer "api/2/users" \
					"${_access_token}" \
					"application/json" \
					"${_json}" > user.json
```

A created user is not active. To activate them we can either send them an activation e-mail or set them a password. The sending of an activation e-mail is the preferable way, as in this case a user can set their own password by themselves. We use a set password way for demo purposes and a fake e-mail is used. To set a password we send a simple JSON and POST request to `/users/{_user_id}/password` end-point.

```bash
# Call a function to pipe JSON from file, extract JSON property
_user_id=$(_get_id_from_file user.json)

# Body JSON, to assign a password and activate the user
# NEVER STORE A PASSWORD IN PLAIN TEXT FILE
# THIS CODE IS FOR API DEMO PURPOSES ONLY
# AS IT USES FAKE E-MAIL AND ACTIVATION E-MAIL CAN'T BE SENT
_json='{
  		"password": "MyStrongP@ssw0rd"
	   }'

# To activate a user by setting a password
# POST API call using function defined in basis_functions.sh
# with following parameters
# $1 - an API endpoint to call
# $2 - a bearer token Bearer Authentication
# $3 - Content-Type
# $4 - POST data
_post_api_call_bearer "api/2/users/${_user_id}/password" \
					"${_access_token}" \
					"application/json" \
					"${_json}"
```

At this point, we've created a partner, a customer, enable offering items for them, create a user and activate them.

## Get a tenant usage

A very common task is to check a tenant’s usage. It's a simple task. We just need to make a GET request to `/tenants/${_tenant_id}/usages` end-point, as result we receive a list with current usage information in JSON format.

```bash
# Call a function to pipe JSON from file, extract JSON property, remove quotas from the property's value
_access_token=$(_get_access_token_from_file api_token.json)

# Get Root tenant_id for the API Client
# Pipe JSON from file, extract JSON property, remove quotas from the property's value
_tenant_id=$(_get_tenant_id_from_file api_client.json)

# To get a tenant usage
# GET call using function defined in basis_functions.sh
# with following parameters
# $1 - an API endpoint to call
# $2 - a bearer token Bearer Authentication
# The result is stored in "${_tenant_id}_usage.json" file
_get_api_call_bearer "api/2/tenants/${_tenant_id}/usages" \
					 "${_access_token}" > "${_tenant_id}_usage.json"
```

It's very useful to store usage information for further processing. In our example we use response JSON format to store it in a file.

## Create and download simple report

The reporting capability of the Acronis Cyber Cloud gives you advanced capabilities to understand usage. In the following simple example, we create a one-time report in csv format, and then download it. To check other options, please, navigate to the Acronis Cyber Platform [documentation](https://developer.acronis.com/doc/platform/management/v2/#/http/developer-s-guide/managing-reports).

To create a report to `save`, we build a body JSON and make a POST request to `/reports` end-point. Then we look into stored reports with specified `$_report_id` making a GET request to `/reports/${_report_id}/stored` endpoint.

```bash
# Call a function to pipe JSON from file, extract JSON property, remove quotas from the property's value
_access_token=$(_get_access_token_from_file api_token.json)

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
# $2 - a bearer token Bearer Authentication
# $3 - Content-Type
# $4 - POST data
# The result is stored in created_report.json file
_post_api_call_bearer "api/2/reports" \
					"${_access_token}" \
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
	# $2 - a bearer token Bearer Authentication
	# The result is stored in "${_report_id}_report.json" file
	_get_api_call_bearer "api/2/reports/${_report_id}/stored" \
					 "${_access_token}" > "${_report_id}_report_status.json"


	_report_status=$(jq '.items[0].status' < "${_report_id}_report_status.json" | sed -e 's/^"//' -e 's/"$//')

	sleep 2s
done

# For sample purposes we use 1 report from stored -- as we use once report
# MUST BE CHANGED if you want to deal with scheduled one or you have multiple reports
_stored_report_id=$(jq '.items[0].id' < "${_report_id}_report_status.json" | sed -e 's/^"//' -e 's/"$//')
```

And finally, we download the report created using a GET request to
`/reports/${_report_id}/stored/${_stored_report_id}` and save it in `${_report_id}_report.csv` file for further processing.

```bash
# Download the report
# The result is stored in "${_report_id}_report.csv" file
# Response is gzip-ed so we need to add --compressed to have an output file decompressed
# _base_url is loaded from config file in 00.basis_functions.sh
curl	--compressed \
		-X GET \
		--url "${_base_url}api/2/reports/${_report_id}/stored/${_stored_report_id}" \
		-H "Authorization: Bearer ${_access_token}" \
		-o "${_report_id}_report.csv"
```

## Basis functions used in code

As you can see, to simplify code we created some basis functions to call the API. Below, you can find those functions with base descriptions

`_die` function is used to output error to the `STDERR` and stop the execution of scripts


```bash
# Print errors info to STDERR and exit execution
_die() { printf ":: %s\n\n" "$*" >&2; exit 1; }
```

`_config_get_value` function is used to read values from configuration files

```bash
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
```

`_call` and `_response` functions are used to implement API calls trace

```bash
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
```

`_get_api_call_basic` function is used to make a GET API call with a Basic Authentication using `endpoint`, `login` and `password` provided. The function checks response error codes and return only a response body.

```bash
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
```

`_get_api_call_bearer` function is used to make a GET API call with a Bearer Authentication using `endpoint`, bearer `token` provided. The function checks response error codes and return only a response body.

```bash
# GET API call with Bearer Authentication
# $1 - an API endpoint to call
# $2 - a bearer token Bearer Authentication
_get_api_call_bearer () {

  local _response_body
  local _response_code

  _call \
  curl	-s \
		-X GET \
		--url "${_base_url}${1}" \
		-H "Authorization: Bearer ${2}" \
		-H "Accept: application/json" \
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
```

`_get_api_call_bearer_with_response_code` function is used to make a GET API call with a Bearer Authentication using `endpoint`, bearer `token` provided, but it returns not only a response body, but a response code as well.

```bash
# GET API call with Bearer Authentication
# $1 - an API endpoint to call
# $2 - a bearer token Bearer Authentication
_get_api_call_bearer_with_response_code () {

  local _response_body
  local _response_code

  _call \
  curl	-s \
		-X GET \
		--url "${_base_url}${1}" \
		-H "Authorization: Bearer ${2}" \
		-H "Accept: application/json" \
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
```

`_post_api_call_basic` function is used to make a POST API call with a Basic Authentication using `endpoint`, `login` and `password` provided, POST data and content-type of the request body. The function checks response error codes and return only a response body.

```bash
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
```

`_post_api_call_bearer` function is used to make a POST API call with a Bearer Authentication using `endpoint`, bearer `token` provided, POST `data` and `content-type` of the request body. The function checks response error codes and return only a response body.

```bash
# POST API call with Bearer Authentication
# $1 - an API endpoint to call
# $2 - a bearer token Bearer Authentication
# $3 - Content-Type
# $4 - POST data
_post_api_call_bearer () {

  local _response_body
  local _response_code

  _call \
  curl	-s \
		-X POST \
		--url "${_base_url}${1}" \
		-H "Authorization: Bearer ${2}" \
		-H "Accept: application/json" \
		-H "Content-type: ${3}" \
		--data-raw "${4}" \
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
```

`_put_api_call_bearer` function is used to make a PUT API call with a Bearer Authentication using `endpoint`, bearer `token` provided, PUT `data` and `content-type` of the request body. The function checks response error codes and return only a response body.

```bash
# PUT API call with Bearer Authentication
# $1 - an API endpoint to call
# $2 - a bearer token Bearer Authentication
# $3 - Content-Type
# $4 - POST data
_put_api_call_bearer () {

  local _response_body
  local _response_code

  _call \
  curl	-s \
		-X PUT \
		--url "${_base_url}${1}" \
		-H "Authorization: Bearer ${2}" \
		-H "Accept: application/json" \
		-H "Content-type: ${3}" \
		--data-raw "${4}" \
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
```

## Summary
Now you know how to use Base operations with the Acronis Cyber Platform API:
1.	Create an API Client for the Acronis Cyber Platform API access
2.	Issue a token for secure access for the API
3.	Establish a simple procedure to renew/refresh the token
4.	Create a partner and a customer tenants and enable offering items for them.
5.	Create a user for a customer tenant and activate them.
6.	Receive simple usage information for a tenant.
7.	Create and download reports for usage.

Get started today, register on the [Acronis Developer Portal](https://developer.acronis.com/) and see the code samples available, you can also review solutions available in the [Acronis Cyber Cloud Solutions Portal](https://solutions.acronis.com/).

***
Copyright © 2019-2020 Acronis International GmbH. This is distributed under MIT license.
***
