#!/bin/bash

echo "This script will update your DDNS address at afraid.org to your current IP address, if necessary, based on the values you set.
Hosted on GitHub: https://github.com/Feriman22/freednsupdater
Written by Feriman (Feriman.com)

Set these variables in your docker-compose.yml:
APIURL # Required. Go to https://freedns.afraid.org/api/, login and click on the "ASCII" link. Add the URL to your browser as a variable
DDNSDOMAIN # Optional. If you have multiple domains, define them, otherwise the script will exit.
CheckAgainInXSec # Optional. If you set a valid number, the external IP will be checked for changes every $CheckAgainInXSec seconds. The minimum value is 10.

Debug:
All logs are stored in the /tmp/afraid-ddns-ip-updater.log file inside the container.

Exit codes:
70: APIURL variable is missing
71: You have multiple DDNS addresses, and have not defined the DDNSDOMAIN variable
72: curl command not found (not installed or not placed in default paths)
73: Do not flood anyone. You have set the CheckAgainInXSec value too low. It's a built-in feature to avoid overloading afraid.org or any IP check provider.

"

# Variables
[ ! "$APIURL" ] && echo "$(date) - ERROR: APIURL variable is missing. Exit." | tee "$LOG" && exit 70
[[ "$CheckAgainInXSec" != ?(-)+([0-9]) ]] && CheckAgainInXSec=300  # Set default if not exists or invalid
IPSTORE="/tmp/externalip.txt"
LOG="/tmp/afraid-ddns-ip-updater.log"

# Generate variables
[ "$(curl -s "$APIURL" | wc -l)" -gt "1" ] && [ ! "$DDNSDOMAIN" ] && echo "$(date) - ERROR: You have multiple DDNS addresses, and have not defined the DDNSDOMAIN variable. Exit." | tee "$LOG" && exit 71
[ ! "$DDNSDOMAIN" ] && DDNSDOMAIN="$(curl -s "$APIURL" | awk -F'|' '{print $1;}')"
UPDATEURL="$(curl -s "$APIURL" | awk -F'|' '{print $3;}')"

# Check curl command
! command -v curl > /dev/null && echo "$(date) - ERROR: curl command not found. Exit." | tee "$LOG" && exit 72

# Avoid flood
[ "$CheckAgainInXSec" -lt "10" ] && echo "$(date) - ERROR: Do not flood anyone. You have set the CheckAgainInXSec value too low. Exit." | tee "$LOG" && exit 73

# Valiadte IP function
validateip() {
	[[ "$1" =~ ^(([1-9]?[0-9]|1[0-9][0-9]|2([0-4][0-9]|5[0-5]))\.){3}([1-9]?[0-9]|1[0-9][0-9]|2([0-4][0-9]|5[0-5]))$ ]]
}

# Update DDNS IP on afraid.org function
updateip() {
	curl -s "$UPDATEURL"
}

# Get the current IP of DDNS from afraid.org function
getddnsip() {
	DDNSIP=$(curl -s "$APIURL" | awk -F'|' '{print $2;}')
	! validateip "$DDNSIP" && echo "$(date) - WARNING: Invalid DDNS IP." | tee "$LOG"
}

# Core of the script - run periodically
while true; do

	# Get current external IP - check from random IP check providers, and exit on the first working one
	providers=("ident.me" "ipinfo.io/ip" "ifconfig.me" "api.ipify.org")
	for provider in "${providers[@]}"; do
		CURRENT_IP="$(curl -s "$provider")"
		# Validate the IP address
		if ! validateip "$CURRENT_IP"; then
			echo "$(date) - WARNING: $provider is not working now, the IP is invalid ($CURRENT_IP). Try to the next one." | tee "$LOG" && continue
		else
			GOTIP="true"
			break
		fi
	done | shuf

	# Validate that we have an IP from one IP provider
	if [ "$GOTIP" ]; then

		# Enter here only first time
		if [ ! -f "$IPSTORE" ]; then
			getddnsip
			[ "$CURRENT_IP" != "$DDNSIP" ] && updateip && IPUPDATED="true"

		# Check if the stored IP is different than the current IP
		elif [ "$CURRENT_IP" != "$(cat $IPSTORE)" ]; then

			# Check if freedns.afraid.org is available
			if curl -s https://freedns.afraid.org > /dev/null; then

				# Update the IP of DDNS
				updateip
			else
				echo "$(date) - ERROR: freedns.afraid.org is not available." | tee "$LOG"
			fi
		fi
	else
		echo "$(date) - WARNING: We don't have a valid IP. Current value of IP is $CURRENT_IP" | tee "$LOG"
	fi

	# Sleep for $CheckAgainInXSec seconds
	sleep "$CheckAgainInXSec"

	# Validate that the DDNS IP has been updated
	if [ "$IPUPDATED" ]; then
		getddnsip
		if [ "$CURRENT_IP" == "$DDNSIP" ]; then
			echo "$(date) - INFO: IP has been updated to $CURRENT_IP" | tee "$LOG"
			echo "$CURRENT_IP" > "$IPSTORE"
			unset IPUPDATED DDNSIP
		else
			echo "$(date) - WARNING: IP update failed this time (too low CheckAgainInXSec value?). Maybe next time." | tee "$LOG"
			unset DDNSIP
		fi
	fi

	# Unset the GOTIP variable before start next run
	unset GOTIP
done
