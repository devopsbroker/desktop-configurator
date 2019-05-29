#!/bin/bash

#
# configure-samba.sh - DevOpsBroker script for configuring Samba
#
# Copyright (C) 2018 Edward Smith <edwardsmith@devopsbroker.org>
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
# Developed on Ubuntu 16.04.4 LTS running kernel.osrelease = 4.13.0-43
#
# This configuration script performs the following tasks:
#   o Creates /etc/samba/private directory for the passdb.tdb file
#   o Installs or updates /etc/samba/smbshare.conf
#   o Installs or updates /etc/samba/smb.conf
#   o Disables the NetBIOS service (nmbd)
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

# Load /etc/devops/functions-admin.conf if FUNC_ADMIN_CONFIG is unset
if [ -z "$FUNC_ADMIN_CONFIG" ] && [ -f /etc/devops/functions-admin.conf ]; then
	source /etc/devops/functions-admin.conf
fi

${FUNC_ADMIN_CONFIG?"[1;91mCannot load '/etc/devops/functions-admin.conf': No such file[0m"}

# Load /etc/devops/functions-io.conf if FUNC_IO_CONFIG is unset
if [ -z "$FUNC_IO_CONFIG" ] && [ -f /etc/devops/functions-io.conf ]; then
	source /etc/devops/functions-io.conf
fi

${FUNC_IO_CONFIG?"[1;91mCannot load '/etc/devops/functions-io.conf': No such file[0m"}

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

# Set smb.conf.tpl location and make it executable
smbConfTpl=$(isExecutable "$SCRIPT_DIR"/smb.conf.tpl)

################################## Variables ##################################

## Options
DEFAULT_NIC=${1:-"$($EXEC_IP -4 route show default | $EXEC_AWK '{ print $5 }')"}

## Variables
export TMPDIR=${TMPDIR:-'/tmp'}
echoOnExit=false

################################### Actions ###################################

# Clear screen only if called from command line
if [ $SHLVL -eq 1 ]; then
	clear
fi

printBox "DevOpsBroker $UBUNTU_RELEASE Samba Configurator" 'true'

#
# /etc/samba/ Configuration
#

# Create /etc/samba/private directory
if [ ! -d /etc/samba/private ]; then
	printInfo 'Creating /etc/samba/private directory'

	# Make the private directory for the passdb.tdb file
	$EXEC_MKDIR --mode=0750 /etc/samba/private

	echoOnExit=true
fi

# Install /etc/samba/smbshare.conf
installConfig 'smbshare.conf' "$SCRIPT_DIR" /etc/samba

# Install /etc/samba/smb.conf
if ! $EXEC_GREP -Fq 'DevOpsBroker' /etc/samba/smb.conf; then
	printInfo 'Installing /etc/samba/smb.conf'

	# Execute template script
	"$smbConfTpl" "$DEFAULT_NIC" > "$TMPDIR"/smb.conf

	# Install as root:root with rw-r--r-- privileges
	$EXEC_INSTALL -b --suffix .orig -o root -g root -m 644 "$TMPDIR"/smb.conf /etc/samba

	# Clean up
	$EXEC_RM "$TMPDIR"/smb.conf

	printInfo 'Restart smbd Service'
	$EXEC_SYSTEMCTL restart smbd.service

	echoOnExit=true

elif [ "$smbConfTpl" -nt /etc/samba/smb.conf ]; then
	printInfo 'Updating /etc/samba/smb.conf'

	# Execute template script
	"$smbConfTpl" "$DEFAULT_NIC" > "$TMPDIR"/smb.conf

	# Install as root:root with rw-r--r-- privileges
	$EXEC_INSTALL -b --suffix .bak -o root -g root -m 644 "$TMPDIR"/smb.conf /etc/samba

	# Clean up
	$EXEC_RM "$TMPDIR"/smb.conf

	printInfo 'Restart smbd Service'
	$EXEC_SYSTEMCTL restart smbd.service

	echoOnExit=true
fi

# Disable nmbd service
set +o errexit
if $EXEC_SYSTEMCTL status nmbd.service | $EXEC_GREP -Fq 'Active: active (running)'; then
	printInfo 'Disabling Samba NetBIOS nameserver'

	# Stop and disable nmbd service
	$EXEC_SYSTEMCTL stop nmbd
	$EXEC_SYSTEMCTL disable nmbd

	echoOnExit=true
fi
set -o errexit

if [ "$echoOnExit" == 'true' ]; then
	echo
fi

exit 0
