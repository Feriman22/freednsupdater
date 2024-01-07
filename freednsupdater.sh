#!/bin/bash

echo "This script will update your DDNS address at afraid.org to your current IP address, if necessary, based on the values you set.
Hosted on GitHub: https://github.com/Feriman22/freednsupdater
Written by Feriman (Feriman.com)

Set these variables in your docker-compose.yml:
APIURL # Required. Go to https://freedns.afraid.org/api/, login and click on the "ASCII" link. Add the URL to your browser as a variable.
	# Note: You will need to update this every time you change your password on afraid.org
DDNSDOMAIN # Optional. If you have multiple domains, define them, otherwise the script will exit.
CheckAgainInXSec # Optional. If you set a valid number, the external IP will be checked for changes every $CheckAgainInXSec seconds. The minimum value is 10.

Debug:
All logs are stored in the /tmp/afraid-ddns-ip-updater.log file inside the container.

Exit codes:
70: APIURL variable is missing
71: You have multiple DDNS addresses, and have not defined the DDNSDOMAIN variable
72: Failed to get DDNSDOMAIN variable. Do you have an Internet connection?
73: wget command not found (not installed or not placed in default paths)
74: Do not flood anyone. You have set the CheckAgainInXSec value too low. It's a built-in feature to avoid overloading afraid.org or any IP check provider.

------- SCRIPT STARTS -------

"

# Main variables
[ ! "$APIURL" ] && echo "$(date) - ERROR: APIURL variable is missing. Exit." | tee "$LOG" && exit 70
[[ "$CheckAgainInXSec" != ?(-)+([0-9]) ]] && CheckAgainInXSec=300  # Set default if not exists or invalid
IPSTORE="/tmp/externalip.txt"
LOG="/tmp/afraid-ddns-ip-updater.log"

# Validate & generate variables
[ "$(wget -qO- "$APIURL" | grep -c 'afraid.org')" -gt "1" ] && [ ! "$DDNSDOMAIN" ] && echo "$(date) - ERROR: You have multiple DDNS addresses, and have not defined the DDNSDOMAIN variable. Exit." | tee "$LOG" && exit 71
[ ! "$DDNSDOMAIN" ] && DDNSDOMAIN="$(wget -qO- "$APIURL" | cut -d '|' -f 1)"
[ ! "$DDNSDOMAIN" ] && echo "$(date) - ERROR: Failed to get DDNSDOMAIN variable. Do you have an Internet connection? Exit." | tee "$LOG" && exit 72
UPDATEURL="$(wget -qO- "$APIURL" | grep "$DDNSDOMAIN" | cut -d '|' -f 3)"

# Remove local IP cache file to avoid issues
rm -f "$IPSTORE"

# wget command verification
! command -v wget > /dev/null && echo "$(date) - ERROR: wget command not found. Exit." | tee "$LOG" && exit 73

# Avoid flooding
[ "$CheckAgainInXSec" -lt "10" ] && echo "$(date) - ERROR: Do not flood anyone. You have set the CheckAgainInXSec value too low. Exit." | tee "$LOG" && exit 74

# Function: Validate IP
validateip() {
	[[ "$1" =~ ^(([1-9]?[0-9]|1[0-9][0-9]|2([0-4][0-9]|5[0-5]))\.){3}([1-9]?[0-9]|1[0-9][0-9]|2([0-4][0-9]|5[0-5]))$ ]]
}

# Function: Update DDNS IP on afraid.org
updateip() {
	echo "$(date) - INFO: Updating IP for $DDNSDOMAIN..."
	wget -qO- "$UPDATEURL"
 	IPUPDATED="true"
}

# Function: Get the current IP of DDNS from afraid.org
getddnsip() {
	DDNSIP=$(wget -qO- "$APIURL" | grep "$DDNSDOMAIN" | cut -d '|' -f 2)
	! validateip "$DDNSIP" && echo "$(date) - WARNING: Invalid DDNS IP ($DDNSIP) for $DDNSDOMAIN." | tee "$LOG"
}

# Core of the script - run periodically
while true; do
	# List of IP providers
	providers=("ident.me" "ipinfo.io/ip" "ifconfig.me" "api.ipify.org")
 	# Shuffle the array
	shuffled_providers=($(shuf -e "${providers[@]}"))
	# Get current external IP - check from random IP check providers, and exit on the first working one
	for provider in "${shuffled_providers[@]}"; do
		CURRENT_IP="$(wget -qO- "$provider")"
		# Validate the IP address
		if validateip "$CURRENT_IP"; then
  			break
     		else
			echo "$(date) - WARNING: $provider is not working now, the IP is invalid ($CURRENT_IP). Try to the next one." | tee "$LOG" && continue
		fi
	done

	# Validate that we have an IP from one IP provider
	if [ "$CURRENT_IP" ]; then
		# Enter here only first time
		if [ ! -f "$IPSTORE" ]; then
  			echo "$(date) - INFO: Script has been started. Check the IP of $DDNSDOMAIN"
			getddnsip
   			if [ "$CURRENT_IP" == "$DDNSIP" ]; then
      				echo "$(date) - INFO: The IP already set for $DDNSDOMAIN."
      				echo "$CURRENT_IP" > "$IPSTORE"
	  			unset DDNSIP
	  		else
     				updateip
			fi

		# Check if the stored IP is different than the current IP
		elif [ "$CURRENT_IP" != "$(cat $IPSTORE)" ]; then
			# Check if freedns.afraid.org is available
			if wget -q -O /dev/null https://freedns.afraid.org > /dev/null; then
				# Update the IP of DDNS
				updateip
			else
				echo "$(date) - ERROR: freedns.afraid.org is not available at this time." | tee "$LOG"
			fi
		fi
	else
		echo "$(date) - WARNING: We don't have a valid IP. Current value of IP is $CURRENT_IP" | tee "$LOG"
	fi

	# Sleep for $CheckAgainInXSec seconds
	sleep "$CheckAgainInXSec"

	# Verify that the DDNS IP has been updated
	if [ "$IPUPDATED" ]; then
		getddnsip
		if [ "$CURRENT_IP" == "$DDNSIP" ]; then
			echo "$(date) - INFO: Verification completed. The $CURRENT_IP IP has been set for $DDNSDOMAIN" | tee "$LOG"
			echo "$CURRENT_IP" > "$IPSTORE"
			unset IPUPDATED DDNSIP
		else
			echo "$(date) - WARNING: IP update failed this time (too low CheckAgainInXSec value?). Maybe next time." | tee "$LOG"
			unset DDNSIP
		fi
	fi

	# Unset the CURRENT_IP variable before start next run
	unset CURRENT_IP
done
