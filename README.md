# FreeDNS Updater
Lightweight FreeDDNS IP Updater for afraid.org, based on a [Docker container](https://hub.docker.com/r/feriman25/freednsupdater).<br><br>
The motivation behind the project is that it is not necessary to use a lot of resources to keep the IP address of your DDNS address fresh. So, for example, this Docker image is an excellent replacement for ddclient. Smaller size, less resources, less code, less chance of something going wrong.<br><br>
It is also resource-efficient from a network point of view, because it only makes an API call to afraid.org when the container is started (it checks once to see if it is in sync) or when it needs to update the IP address because it has been changed. Otherwise it is stored locally and works from a cache file. And it retrieves the external IP address from different providers, selecting them randomly, so no provider is overloaded.

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
70: APIURL variable is missing. You have to define it in the docker-compose.yml file<br>
71: You have multiple DDNS addresses, and have not defined the DDNSDOMAIN variable<br>
72: curl command not found (not installed or not placed in default paths)<br>
73: Do not flood anyone. You have set the CheckAgainInXSec value too low. It's a built-in feature to avoid overloading afraid.org or any IP check provider.
