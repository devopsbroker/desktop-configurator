#!/usr/bin/bash

#
# ipset-config.sh - DevOpsBroker IPSet firewall script for Ubuntu Desktop machines
#
# Copyright (C) 2019 Edward Smith <edwardsmith@devopsbroker.org>
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
# Developed on Ubuntu 18.04.2 LTS running kernel.osrelease = 4.18.0-25
#
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

## Bash exec variables
IPTABLES=/sbin/iptables
IP6TABLES=/sbin/ip6tables
IPSET=/sbin/ipset

################################### Actions ###################################

# Clear screen only if called from command line
if [ $SHLVL -eq 1 ]; then
	clear
fi

printBox "DevOpsBroker $UBUNTU_RELEASE IPSet Configurator" 'true'

#################################### IPSets ###################################

#
# Set default policies / Flush rules / Delete user-defined chains
# ¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯
printBanner 'Initializing IPSets'

#
# Set default policies / Flush rules / Delete user-defined chains
# ¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯
printInfo 'Initializing iptables RAW Table'
$IPTABLES -t raw -F
$IPTABLES -t raw -X

printInfo 'Initializing iptables MANGLE Table'
$IPTABLES -t mangle -F
$IPTABLES -t mangle -X

printInfo 'Initializing iptables NAT Table'
$IPTABLES -t nat -F
$IPTABLES -t nat -X

printInfo 'Initializing iptables FILTER Table'
$IPTABLES -t filter -F
$IPTABLES -t filter -X

echo

printInfo 'Initializing ip6tables RAW Table'
$IP6TABLES -t raw -F
$IP6TABLES -t raw -X

printInfo 'Initializing ip6tables MANGLE Table'
$IP6TABLES -t mangle -F
$IP6TABLES -t mangle -X

printInfo 'Initializing ip6tables NAT Table'
$IP6TABLES -t nat -F
$IP6TABLES -t nat -X

printInfo 'Initializing ip6tables FILTER Table'
$IP6TABLES -t filter -F
$IP6TABLES -t filter -X

echo

printInfo 'Removing current IPSet configuration'
$IPSET destroy

echo

printBanner 'Configuring IPSets'

# TCP Client Ports Bitmap
# ¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯
printInfo 'Creating tcp_client_ports bitmap'
$IPSET create tcp_client_ports bitmap:port range 1-10240
$IPSET add tcp_client_ports 80       # HTTP
$IPSET add tcp_client_ports 443      # HTTPS

# TCP Service Ports Bitmap
# ¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯
printInfo 'Creating tcp_service_ports bitmap'
$IPSET create tcp_service_ports bitmap:port range 1-10240

# UDP Client Ports Bitmap
# ¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯
printInfo 'Creating udp_client_ports bitmap'
$IPSET create udp_client_ports bitmap:port range 1-10240
$IPSET add udp_client_ports 53        # DNS
$IPSET add udp_client_ports 123       # NTP
$IPSET add udp_client_ports 1124      # WS-Discovery
$IPSET add udp_client_ports 1900      # UPnP
$IPSET add udp_client_ports 5353      # mDNS

# UDP Service Ports Bitmap
# ¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯
printInfo 'Creating udp_service_ports bitmap'
$IPSET create udp_service_ports bitmap:port range 1-10240
$IPSET add udp_service_ports 5353      # mDNS

################################# IPSET-SAVE ##################################

printInfo 'Persisting IPSet configuration'

# Backup existing /etc/network/ipset.conf
if [ -f /etc/network/ipset.conf ]; then
	$EXEC_CP /etc/network/ipset.conf /etc/network/ipset.conf.bak
fi

# Save /etc/network/ipset.conf
$IPSET save > /etc/network/ipset.conf

echo

exit 0
