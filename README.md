# FreeDNS Updater
[![Docker Image Size](https://img.shields.io/docker/image-size/feriman25/freednsupdater/latest?logo=docker&style=for-the-badge)](https://hub.docker.com/r/feriman25/freednsupdater/tags)
[![Docker Pulls](https://img.shields.io/docker/pulls/feriman25/freednsupdater?label=Pulls&logo=docker&style=for-the-badge)](https://hub.docker.com/r/feriman25/freednsupdater/tags)
[![Docker Stars](https://img.shields.io/docker/stars/feriman25/freednsupdater?label=Stars&logo=docker&style=for-the-badge)](https://hub.docker.com/r/feriman25/freednsupdater/tags)
[![Donate](https://img.shields.io/badge/Donate-PayPal-green.svg?style=for-the-badge)](https://paypal.me/BajzaFerenc)<br><br>
Lightweight FreeDDNS IP Updater for afraid.org, based on a [Docker container](https://hub.docker.com/r/feriman25/freednsupdater).<br><br>
The motivation behind the project is that it is not necessary to use a lot of resources to keep the IP address of your DDNS address fresh. So, for example, this Docker image is an excellent replacement for ddclient. Smaller size, less resources, less code, less chance of something going wrong.<br><br>
Just a quick comparison of Docker image sizes:<br>
ddclient: 24.26MB<br>
freednsupdater: 4.02MB<br><br>

It is also resource-efficient from a network point of view, because it only makes an API call to afraid.org when the container is started (it checks once to see if it is in sync) or when it needs to update the IP address because it has been changed. Otherwise it is stored locally and works from a cache file. And it retrieves the external IP address from different providers, selecting them randomly, so no provider is overloaded.
<br><br>
## docker-compose.yml:

    version: '3'

    services:
      freednsupdater:
        image: feriman25/freednsupdater
        container_name: freednsupdater
        environment:
          - APIURL=https://freedns.afraid.org/api/?action=getdyndns&v=2&sha=yourrandomshastring
    #      - DDNSDOMAIN=
    #      - CheckAgainInXSec=300  
        restart: always
        network_mode: bridge
<br><br>
## Available variables in docker-compose.yml:<br>
**APIURL**<br>
Required. Go to https://freedns.afraid.org/api/, login and click on the "ASCII" link. Add the URL to your browser as a variable.<br>
Note: You will need to update this every time you change your password on afraid.org<br><br>
**DDNSDOMAIN**<br>
Optional. If you have one DDNS address, the script will recognize it. However, if you have multiple domains, define them, otherwise the script will exit.<br><br>
**CheckAgainInXSec**<br>
Optional. If you set a valid number, the external IP will be checked for changes every $CheckAgainInXSec seconds. The minimum value is 10.<br>
<br><br>
## Debug:
All logs are stored in the /tmp/afraid-ddns-ip-updater.log file inside the container.
<br><br>
## Exit codes:
70: APIURL variable is missing. You have to define it in the docker-compose.yml file<br>
71: You have multiple DDNS addresses, and have not defined the DDNSDOMAIN variable<br>
72: Failed to get DDNSDOMAIN variable. Do you have an Internet connection?<br>
73: wget command not found (not installed or not placed in default paths)<br>
74: Do not flood anyone. You have set the CheckAgainInXSec value too low. It's a built-in feature to avoid overloading afraid.org or any IP check provider.
<br><br>
## Changelog

**2025-02-23**
- **Fix:** `LOG` and `IPSTORE` variables are now defined before first use. Previously the first error message was piped into `tee ""` (empty filename) and never written to the log file
- **Fix:** `wget` availability check moved before any `wget` call. Previously the check ran after wget was already used, so a missing wget caused silent failures with empty variables
- **Fix:** After the IP provider loop, an invalid (non-empty but malformed) response could slip through the `if [ "$CURRENT_IP" ]` check and trigger a DDNS update with garbage data. Replaced with `validateip "$CURRENT_IP"`
- **Fix:** IP providers now use HTTPS instead of HTTP. HTTP allowed a MITM attacker to return a fake IP and cause the DDNS record to be updated with an arbitrary address
- **Fix:** `$IPSTORE` is now properly quoted in the `cat` call
- **Optimization:** The afraid.org API URL is fetched only once at startup (previously called 3 separate times) and the result is parsed in memory
- **Optimization:** Array shuffling now uses `mapfile` instead of unquoted command substitution, which is safer against word splitting and glob expansion
- **Optimization:** All log messages now consistently use `tee -a` (append mode) and write to both stdout and the log file. Previously some INFO messages were stdout-only and `tee` was overwriting the log file on each call

<br><br>
## Known bugs
- All software has bugs, but we have not yet found any in this one. If you find one, open an issue for it [here on GitHub](https://github.com/Feriman22/freednsupdater/issues).
<br><br>
## Do not forget

If you found my work helpful, I would greatly appreciate it if you could make a **[donation through PayPal](https://paypal.me/BajzaFerenc)** to support my efforts in improving and fixing bugs or creating more awesome scripts. Thank you!

<a href='https://paypal.me/BajzaFerenc'><img height='36' style='border:0px;height:36px;' src='https://raw.githubusercontent.com/Feriman22/portscan-protection/master/paypal-donate.png' border='0' alt='Donate with Paypal' />  
