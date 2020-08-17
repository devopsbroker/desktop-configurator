#!/usr/bin/bash

#
# configure-ssh.sh - DevOpsBroker script for configuring ssh-agent for users
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
# Developed on Ubuntu 20.04.1 LTS running kernel.osrelease = 5.4.0-42
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
if [ "$USER" = 'root' ]; then
	printError $SCRIPT_EXEC 'Permission denied (you cannot be root)'
	exit 1
fi

################################## Variables ##################################

## Bash exec variables
EXEC_SUDO=/usr/bin/sudo

## Options
username=${1:-$USERNAME}

## Variables

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ OPTION Parsing ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

userRecord="$($EXEC_GETENT passwd $username)"

# Ensure the argument is a valid username
if [ ${#userRecord} -eq 0 ]; then
	printError "$SCRIPT_EXEC" "Cannot find '$username': No such user"
	echo
	printUsage "$SCRIPT_EXEC USER"

	exit 1
fi

IFS=':'; userInfo=($userRecord); unset IFS;

# Ensure the user is using bash for the shell
if [ "${userInfo[6]}" != '/bin/bash' ]; then
	printError "$SCRIPT_EXEC" "User shell not bash: ${userInfo[6]}"
	exit 1
fi

userhome="${userInfo[5]}"

################################### Actions ###################################

#
# Install ssh-agent.service
#

if [ ! -f "$userhome"/.config/systemd/user/ssh-agent.service ]; then
	printInfo 'Installing systemd user service ssh-agent.service'

	# Install as $username:$username with rw-r--r-- privileges
	$EXEC_INSTALL -o $username -g $username -m 644 "$SCRIPT_DIR"/systemd/ssh-agent.service "$userhome"/.config/systemd/user

	# Need XDG_RUNTIME_DIR and DBUS_SESSION_BUS_ADDRESS
	$EXEC_SUDO -u $username XDG_RUNTIME_DIR="$XDG_RUNTIME_DIR" DBUS_SESSION_BUS_ADDRESS="$DBUS_SESSION_BUS_ADDRESS" $EXEC_SYSTEMCTL --user daemon-reload

	printInfo 'Enabling systemd user service ssh-agent.service'
	$EXEC_SUDO -u $username XDG_RUNTIME_DIR="$XDG_RUNTIME_DIR" DBUS_SESSION_BUS_ADDRESS="$DBUS_SESSION_BUS_ADDRESS" $EXEC_SYSTEMCTL --user enable ssh-agent.service

	printInfo 'Starting systemd user service ssh-agent.service'
	$EXEC_SUDO -u $username XDG_RUNTIME_DIR="$XDG_RUNTIME_DIR" DBUS_SESSION_BUS_ADDRESS="$DBUS_SESSION_BUS_ADDRESS" $EXEC_SYSTEMCTL --user start ssh-agent.service
fi

exit 0
