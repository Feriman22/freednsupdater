# FreeDNS Updater
Lightweight FreeDDNS IP Updater for afraid.org, based on a Docker container

### Set these variables in your docker-compose.yml:<br>
**APIURL**<br>
Required. Go to https://freedns.afraid.org/api/, login and click on the "ASCII" link. Add the URL to your browser as a variable.<br>
Note: You will need to update this every time you change your password on afraid.org<br><br>
**DDNSDOMAIN**<br>
Optional. If you have multiple domains, define them, otherwise the script will exit.<br><br>
**CheckAgainInXSec**<br>
Optional. If you set a valid number, the external IP will be checked for changes every $CheckAgainInXSec seconds. The minimum value is 10.<br>

### docker-compose.yml:

    version: '3'

    services:
      freednsupdater:
        image: feriman25/freednsupdater
        environment:
          - APIURL=https://freedns.afraid.org/api/?action=getdyndns&v=2&sha=yourrandomshastringishere
          - DDNSDOMAIN=yourdomain.mooo.com # Optional
          - CheckAgainInXSec=300 # Optional


### Debug:
All logs are stored in the /tmp/afraid-ddns-ip-updater.log file inside the container.

### Exit codes:
70: APIURL variable is missing<br>
71: You have multiple DDNS addresses, and have not defined the DDNSDOMAIN variable<br>
72: curl command not found (not installed or not placed in default paths)<br>
73: Do not flood anyone. You have set the CheckAgainInXSec value too low. It's a built-in feature to avoid overloading afraid.org or any IP check provider.
