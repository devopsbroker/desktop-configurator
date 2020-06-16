#!/usr/bin/bash

#
# configure-resolved.sh - DevOpsBroker script for configuring systemd-resolved DNS server
#
# Copyright (C) 2020 Edward Smith <edwardsmith@devopsbroker.org>
#
# This program is free software: you can redistribute it and/or modify it under
# the terms of the GNU General Public License as published by the Free Software
# Foundation, either version 3 of the License, or (at your option) any later
# version.
#
# This program is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
# details.
#
# You should have received a copy of the GNU General Public License along with
# this program.  If not, see <http://www.gnu.org/licenses/>.
#
# -----------------------------------------------------------------------------
# Developed on Ubuntu 20.04 LTS running kernel.osrelease = 5.4.0-31
#
# Useful Linux Command-Line Utilities
# ¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯
# Use DNS lookup utility to see systemd-resolved in action (run twice):
#   o dig ubuntu.com
#
# Query Internet name servers interactively:
#   o nslookup google.com
# -----------------------------------------------------------------------------
#

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ Preprocessing ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# Load /etc/devops/ansi.conf if ANSI_CONFIG is unset
if [ -z "$ANSI_CONFIG" ] && [ -f /etc/devops/ansi.conf ]; then
	source /etc/devops/ansi.conf
fi

${ANSI_CONFIG?"[1;91mCannot load '/etc/devops/ansi.conf': No such file[0m"}

# Load /etc/devops/exec.conf if EXEC_CONFIG is unset
if [ -z "$EXEC_CONFIG" ] && [ -f /etc/devops/exec.conf ]; then
	source /etc/devops/exec.conf
fi

${EXEC_CONFIG?"[1;91mCannot load '/etc/devops/exec.conf': No such file[0m"}

# Load /etc/devops/functions.conf if FUNC_CONFIG is unset
if [ -z "$FUNC_CONFIG" ] && [ -f /etc/devops/functions.conf ]; then
	source /etc/devops/functions.conf
fi

${FUNC_CONFIG?"[1;91mCannot load '/etc/devops/functions.conf': No such file[0m"}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ Robustness ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

set -o errexit                 # Exit if any statement returns a non-true value
set -o nounset                 # Exit if use an uninitialised variable
set -o pipefail                # Exit if any statement in a pipeline returns a non-true value
IFS=$'\n\t'                    # Default the Internal Field Separator to newline and tab

## Script information
SCRIPT_INFO=( $($EXEC_SCRIPTINFO "$BASH_SOURCE") )
SCRIPT_DIR="${SCRIPT_INFO[0]}"
SCRIPT_EXEC="${SCRIPT_INFO[1]}"

# Display error if not running as root
if [ "$USER" != 'root' ]; then
	printError $SCRIPT_EXEC 'Permission denied (you must be root)'
	exit 1
fi

################################## Variables ##################################

## Variables
echoOnExit=false
restartResolved=false

################################### Actions ###################################

# Clear screen only if called from command line
if [ $SHLVL -eq 1 ]; then
	clear
fi

printBox "DevOpsBroker $UBUNTU_RELEASE Systemd-Resolved Configurator" 'true'

#
# /etc/systemd/resolved.conf.d/ Configuration
#

if [ ! -d "/etc/systemd/resolved.conf.d" ]; then
  printInfo 'Creating /etc/systemd/resolved.conf.d directory'
  $EXEC_MKDIR --parents --mode=0755 /etc/systemd/resolved.conf.d
fi

if [ ! -f /etc/systemd/resolved.conf.d/10-dns-servers.conf ]; then
	printInfo 'Configuring systemd-resolved DNS server'

	# Install as root:root with rw-r--r-- privileges
	$EXEC_INSTALL -o root -g root -m 644 "$SCRIPT_DIR"/resolved.conf.d/10-dns-servers.conf /etc/systemd/resolved.conf.d

	echoOnExit=true
	restartResolved=true

elif [ "$SCRIPT_DIR"/resolved.conf.d/10-dns-servers.conf -nt /etc/systemd/resolved.conf.d/10-dns-servers.conf ]; then
	printInfo 'Updating systemd-resolved DNS server configuration'

	# Install as root:root with rw-r--r-- privileges
	$EXEC_INSTALL -b --suffix .bak -o root -g root -m 644 "$SCRIPT_DIR"/resolved.conf.d/10-dns-servers.conf /etc/systemd/resolved.conf.d

	echoOnExit=true
	restartResolved=true
fi

#
# Restart systemd-resolved.service
#

if [ "$restartResolved" == 'true' ]; then
	printInfo 'Restarting systemd-resolved.service'
	$EXEC_SYSTEMCTL restart systemd-resolved.service
fi

if [ "$echoOnExit" == 'true' ]; then
	echo
fi

exit 0
