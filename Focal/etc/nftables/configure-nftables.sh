#!/usr/bin/bash

#
# configure-nftables.sh - DevOpsBroker script for nftables configurations
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
# Developed on Ubuntu 20.04 LTS running kernel.osrelease = 5.4.0-37
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

################################## Functions ##################################

# ¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯
# Function:     installPackage
# Description:  Installs the specified package, if not already installed
#
# Parameter $1: The file to check for existence; install if not present
# Parameter $2: The name of the package to install
# -----------------------------------------------------------------------------
function installPackage() {
	INSTALL_PKG='false'

	if [ ! -f "$1" ]; then
		printBanner "Installing $2"
		$EXEC_APT -y install $2
		echo

		INSTALL_PKG='true'
	fi
}

# ¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯
# Function:     uninstallPackage
# Description:  Uninstalls the specified package, if already installed
#
# Parameter $1: The file to check for existence; uninstall if present
# Parameter $2: The name of the package to uninstall
# -----------------------------------------------------------------------------
function uninstallPackage() {
	if [ -f "$1" ]; then
		printBanner "Uninstalling $2"
		$EXEC_APT -y purge $2
		echo
	fi
}

################################## Variables ##################################

## Variables
ALL_IFACES=($($EXEC_IP -br link show | $EXEC_AWK '{ print $1 }' | $EXEC_GREP -Fv lo))

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ OPTION Parsing ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~


################################### Actions ###################################

# Clear screen only if called from command line
if [ $SHLVL -eq 1 ]; then
	clear
fi

printBox "DevOpsBroker $UBUNTU_RELEASE nftables Configurator" 'true'

# Uninstall ufw
uninstallPackage '/usr/sbin/ufw' 'ufw'

# Uninstall iptables
uninstallPackage '/usr/sbin/iptables' 'iptables'

# Uninstall ipset
uninstallPackage '/sbin/ipset' 'ipset'

# Install nftables
installPackage '/usr/sbin/nft' 'nftables'

# Create /etc/nftables directory if not exists
if [ ! -d "/etc/nftables" ]; then
	$EXEC_MKDIR /etc/nftables
fi

# Install nftables scripts
if [ ! -f "/etc/nftables/nftables-private.sh" ]; then
	printInfo "Installing /etc/nftables/nftables-private.sh"

	# Install as root:root with rw-r--r-- privileges
	$EXEC_INSTALL -o root -g root -m 755 "$SCRIPT_DIR/nftables-private.sh" "/etc/nftables"
	echo

elif [ "$SCRIPT_DIR/nftables-private.sh" -nt "/etc/nftables/nftables-private.sh" ]; then
	printInfo "Updating /etc/nftables/nftables-private.sh"

	# Install as root:root with rw-r--r-- privileges
	$EXEC_INSTALL -b --suffix .bak -o root -g root -m 755 "$SCRIPT_DIR/nftables-private.sh" "/etc/nftables"
	echo
fi

if [ ! -f "/etc/nftables/nftables-public.sh" ]; then
	printInfo "Installing /etc/nftables/nftables-public.sh"

	# Install as root:root with rw-r--r-- privileges
	$EXEC_INSTALL -o root -g root -m 755 "$SCRIPT_DIR/nftables-public.sh" "/etc/nftables"
	echo

elif [ "$SCRIPT_DIR/nftables-public.sh" -nt "/etc/nftables/nftables-public.sh" ]; then
	printInfo "Updating /etc/nftables/nftables-public.sh"

	# Install as root:root with rw-r--r-- privileges
	$EXEC_INSTALL -b --suffix .bak -o root -g root -m 755 "$SCRIPT_DIR/nftables-public.sh" "/etc/nftables"
	echo
fi

#
# Configure base public firewall scripts for each interface
#

for IFACE in ${ALL_IFACES[@]}; do

	if [ ! -d "/etc/nftables/$IFACE" ]; then
		printInfo "Creating /etc/nftables/$IFACE directory"

		$EXEC_MKDIR --parents --mode=0755 "/etc/nftables/$IFACE"
	fi

	# Configure the base public network firewall script
	if [ ! -f "/etc/nftables/$IFACE/firewall-public.nft" ]; then
		printInfo "Installing /etc/nftables/$IFACE/firewall-public.nft"

		/etc/nftables/nftables-public.sh $IFACE > /etc/nftables/$IFACE/firewall-public.nft
		$EXEC_CHOWN root:root /etc/nftables/$IFACE/firewall-public.nft
		$EXEC_CHMOD 0755 /etc/nftables/$IFACE/firewall-public.nft
		echo

	elif [ "/etc/nftables/nftables-public.sh" -nt "/etc/nftables/$IFACE/firewall-public.nft" ]; then
		printInfo "Updating /etc/nftables/$IFACE/firewall-public.nft"

		/etc/nftables/nftables-public.sh $IFACE > /etc/nftables/$IFACE/firewall-public.nft
		$EXEC_CHOWN root:root /etc/nftables/$IFACE/firewall-public.nft
		$EXEC_CHMOD 0755 /etc/nftables/$IFACE/firewall-public.nft
		echo
	fi
done

exit 0
