#!/usr/bin/env bash
#
# # WPCLI Security Scan
#
# This script utilizes WPCLI to run checksums on your WordPress installs.
#
# ## Configuration
#
# Configure this script by including a file named
# `wpcli-security-scan-config.sh` with the
# following variables:
#
# - ADMIN=admin-email@example.com
# - SITESTORE=/path/to/vhosts
# - SITEPATH=/path/to/webroot
# - SERVER=web1.example.com
#

ORANGE='\033[0;33m'
NC='\033[0m'

# Get current directory (not bulletproof, source: http://www.ostricher.com/2014/10/the-right-way-to-get-the-directory-of-a-bash-script/)
PWD="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Check for `wpcli-security-scan-config.sh`
if ! $(source $PWD/wpcli-security-scan-config.sh 2>/dev/null); then
    echo 'ERROR: No configuration found! Please setup `wpcli-security-scan-config.sh`.'
    exit
fi

# Load the configuration
source $PWD/wpcli-security-scan-config.sh

SITELIST=($(ls -lh $SITESTORE | awk '{print $9}'))

function wpcli_scan_alert_mail {
	echo -e "The following errors were found on $SITEURL:\n"
	echo -e $OUTPUT
}

function wpcli_finished {
	echo -e "WPCLI Security Scan has completed. If there were any issues, you should have received separate emails for each vhost prior to this email."
}

for SITE in ${SITELIST[@]}; do
	cd $SITESTORE/$SITE$SITEPATH

	printf "\n----------------------------------------\nVerifying ${ORANGE}$SITE${NC}\n----------------------------------------\n"
	
	if ! $(wp core is-installed --allow-root 2>/dev/null); then
		printf "${ORANGE}NOTE:${NC} $SITE is not a WordPress install (${SITESTORE}/${SITE}${SITEPATH}), continuing with next site...\n"
		continue
	fi

	SITEURL=$(wp option get siteurl --allow-root)

	if ! $(wp core verify-checksums --allow-root &>/dev/null); then
		OUTPUT=$(wp core verify-checksums --allow-root 2>&1; printf x); OUTPUT=${OUTPUT%x}
		wpcli_scan_alert_mail | mail -s "$SITE WPCLI Scan Alert" "$ADMIN"
	fi	

done

wpcli_finished | mail -s "$SERVER WPCLI Scan Finished" "$ADMIN"
