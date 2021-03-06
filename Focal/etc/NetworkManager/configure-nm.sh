#!/usr/bin/bash

#
# configure-nm.sh - DevOpsBroker script for configuring NetworkManager
#
# Copyright (C) 2018-2020 Edward Smith <edwardsmith@devopsbroker.org>
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
# Developed on Ubuntu 16.04.5 LTS running kernel.osrelease = 4.15.0-33
#
# The following configuration files are managed by this script:
#
# o /etc/NetworkManager/NetworkManager.conf
# o /etc/NetworkManager/dispatcher.d/10-tuneNetwork
# o /etc/NetworkManager/dispatcher.d/30-nf_conntrack
#
# Useful Linux Command-Line Utilities
# ¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯
# Display the IPv4/IPv6 routing table entries:
#   o ip -4 route show
#   o ip -6 route show
#
# Display network interface configuration including txqueuelength:
#   o ifconfig enp4s0
#
# Display or change Ethernet adapter settings:
#   o sudo ethtool --show-features enp4s0
#   o sudo ethtool --offload enp4s0 tx-checksum-ipv4 on tx-checksum-ipv6 on tx-nocache-copy off
#   o sudo ethtool --offload enp4s0 rx on tx on tso on ufo on sg on gso on
#
# Restart the network interface:
#   o nmcli device disconnect enp4s0 && nmcli device connect enp4s0
#
# NetworkManager Man Pages:
#   o man NetworkManager
#   o man nmcli
#   o man nm-online
#   o man nm-settings
#
# NetworkManager command-line:
#   o nmcli -t --fields UUID connection show
#   o nmcli connection show uuid 604f6d5f-4780-4ee8-806e-d06dacf8702f | grep -F 'connection.interface-name'
# -----------------------------------------------------------------------------
#

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ Preprocessing ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

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

# Load /etc/devops/functions-admin.conf if FUNC_ADMIN_CONFIG is unset
if [ -z "$FUNC_ADMIN_CONFIG" ] && [ -f /etc/devops/functions-admin.conf ]; then
	source /etc/devops/functions-admin.conf
fi

${FUNC_ADMIN_CONFIG?"[1;91mCannot load '/etc/devops/functions-admin.conf': No such file[0m"}

# Load /etc/devops/functions-net.conf if FUNC_NET_CONFIG is unset
if [ -z "$FUNC_NET_CONFIG" ] && [ -f /etc/devops/functions-net.conf ]; then
	source /etc/devops/functions-net.conf
fi

${FUNC_NET_CONFIG?"[1;91mCannot load '/etc/devops/functions-net.conf': No such file[0m"}

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

################################## Functions ##################################

# ¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯
# Function:     installNMScript
# Description:  Installs the specified NetworkManager script
#
# Parameter $1: The NetworkManager script to install
# -----------------------------------------------------------------------------
function installNMScript() {
	local nmScript="$1"
	INSTALL_CONFIG=false

	if [ ! -f "/etc/NetworkManager/$nmScript" ] || [ "$SCRIPT_DIR/$nmScript" -nt "/etc/NetworkManager/$nmScript" ]; then
		printInfo "Installing /etc/NetworkManager/$nmScript"

		# Install as root:root with rwxr-xr-x privileges
		$EXEC_INSTALL -o root -g root -m 755 "$SCRIPT_DIR/$nmScript" "/etc/NetworkManager/$nmScript"

		INSTALL_CONFIG=true
	fi
}

################################## Variables ##################################

## Bash exec variables
EXEC_NMCLI=/usr/bin/nmcli

## Options
NIC="${1:-}"

## Variables
export TMPDIR=${TMPDIR:-'/tmp'}
CONN_UUID=""

################################### Actions ###################################

# Clear screen only if called from command line
if [ $SHLVL -eq 1 ]; then
	clear
fi

printBox "DevOpsBroker $UBUNTU_RELEASE NetworkManager Configurator" 'true'

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ OPTION Parsing ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

if [ -z "$NIC" ]; then

	# Get default NIC if not present on command-line
	NIC="$(getDefaultNIC)"

else
	# Display error if network interface parameter is invalid
	if [ ! -L /sys/class/net/$NIC ]; then
		printError "$SCRIPT_EXEC" "Cannot access '$NIC': No such network interface"
		echo
		printUsage "$SCRIPT_EXEC ${gold}[NIC]"

		exit 1
	fi
fi

# Exit if default interface is a virtual network device (i.e. bridge, tap, etc)
if [[ "$($EXEC_READLINK /sys/class/net/$NIC)" == *"/devices/virtual/"* ]]; then
	printInfo "Default network interface '$NIC' is virtual"
	printInfo 'Exiting'

	exit 0
fi

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ Tasks ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

#
# /etc/NetworkManager Configuration
#

installConfig 'NetworkManager.conf' "$SCRIPT_DIR" /etc/NetworkManager

#
# /etc/NetworkManager/dispatcher.d Configuration
#

installNMScript 'dispatcher.d/10-tuneNetwork'
installNMScript 'dispatcher.d/30-nf_conntrack'

printInfo "Restarting NetworkManager service"
echo
$EXEC_SYSTEMCTL restart NetworkManager.service

echo

exit 0
