#!/usr/bin/bash

#
# configure-cache.sh - DevOpsBroker script for configuring the /cache directory
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
# Developed on Ubuntu 20.04 LTS running kernel.osrelease = 5.4.0-33
#
# Creates the following directory for user caches:
#   o /cache
#
# Moves the user's Firefox cache to /mnt/ramdisk
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

################################## Functions ##################################

# ¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯
# Function:     createDirectory
# Description:  Creates the specified directory if it does not already exist
#
# Parameter $1: Name of the directory to create
# -----------------------------------------------------------------------------
function createDirectory() {
	local dirName="$1"
	local mode=${2:-'0750'}

	if [ ! -d "$dirName" ]; then
		printInfo "Creating $dirName directory"

		$EXEC_MKDIR --parents --mode=$mode "$dirName"
		$EXEC_CHOWN --changes $username:$username "$dirName"
	fi
}

################################## Variables ##################################

## Bash exec variables
EXEC_LSBLK=/usr/bin/lsblk
EXEC_SYMLINK=/usr/local/bin/symlink

## Options
username=${1:-$SUDO_USER}

## Variables
declare -a blockDeviceList=()
declare -a partitionList=()

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ OPTION Parsing ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

userRecord="$($EXEC_GETENT passwd $username || true)"

# Ensure the argument is a valid username
if [ -z "$userRecord" ]; then
	printError "$SCRIPT_EXEC" "Cannot find '$username': No such user"
	echo
	printUsage "$SCRIPT_EXEC USER"

	exit 1
fi

# Set the user's home directory
IFS=':'; userInfo=($userRecord); IFS=$'\n\t';
userhome="${userInfo[5]}"

################################### Actions ###################################

# Clear screen only if called from command line
if [ $SHLVL -eq 1 ]; then
	clear
fi

printBox "DevOpsBroker $UBUNTU_RELEASE Cache Configurator" 'true'

# Move Firefox cache to /mnt/ramdisk
if [ ! -d "/mnt/ramdisk/$username/mozilla/firefox" ] && [ -d "$userhome"/.cache/mozilla/firefox ] ; then
	printInfo 'Moving Firefox cache to /mnt/ramdisk'

	# Create Firefox cache directory for the user in /mnt/ramdisk
	$EXEC_MKDIR --parents --mode=0700 /mnt/ramdisk/$username/mozilla/firefox
	$EXEC_CHOWN --changes -R $username:$username /mnt/ramdisk/$username

	# Create symlink to Firefox cache in /mnt/ramdisk
	$EXEC_CP -a "$userhome"/.cache/mozilla/firefox/* "/mnt/ramdisk/$username/mozilla/firefox"
	$EXEC_RM -rf "$userhome"/.cache/mozilla/firefox
	$EXEC_SYMLINK -o $username:$username "$userhome"/.cache/mozilla/firefox "/mnt/ramdisk/$username/mozilla/firefox"
fi

blockDeviceList=($($EXEC_LSBLK -o NAME | $EXEC_GREP -E "^(nvme|sd)"))

# Don't need to move cache directory if there is only one disk in the system
if [ ${#blockDeviceList[@]} -eq 1 ]; then
	printNotice $SCRIPT_EXEC 'No need to move user cache directory: Only one disk in the system'
	echo
	exit 0
fi

# Find all HDD devices
for blockDevice in "${blockDeviceList[@]}"; do
	if [ "$($EXEC_CAT /sys/block/$blockDevice/queue/rotational)" == "1" ]; then
		if [ "$($EXEC_CAT /sys/block/$blockDevice/removable)" == "0" ]; then
			partitionList+=($($EXEC_LSBLK -ln /dev/$blockDevice -o NAME,MOUNTPOINT | $EXEC_GREP -Ev "(  |\[SWAP\])"))
		fi
	fi
done

# No HDD drives available
if [ ${#partitionList[@]} -eq 0 ]; then
	printNotice $SCRIPT_EXEC 'No hard drive disks available for the user cache'
	echo
	exit 0
fi

# Capture just the partition name
for i in "${!partitionList[@]}"; do
	partition="${partitionList[$i]}"
	partition="$(echo $partition | $EXEC_CUT -d ' ' -f2)"
	partitionList[$i]="$partition"
done

# Add a Skip option to not move the user cache directory
partitionList+=('Skip')

echo "${bold}Which partition do you want to use for the cache directory?${reset}"
select selectedPartition in "${partitionList[@]}"; do
	# Ensure the selection is in the partition list
	set +o errexit
	containsElement "$selectedPartition" "${partitionList[@]}"

	if [ $? -eq 0 ]; then
		break;
	fi
	set -o errexit
done

if [ "$selectedPartition" == 'Skip' ]; then
	echo
	printInfo "Not moving user cache directory"
	echo
	exit 0
fi

# Create /cache directory for user cache
if [ ! -d "$selectedPartition/cache" ]; then
	printInfo "Creating $selectedPartition/cache directory"

	$EXEC_MKDIR --parents --mode=0755 $selectedPartition/cache
	$EXEC_CHOWN --changes root:users $selectedPartition/cache
fi

createDirectory "$selectedPartition/cache/$username" '0700'

# Move $userhome/.cache to $selectedPartition/cache/$username
if [ -d "$selectedPartition/cache/$username" ] && [ ! -L "$userhome"/.cache ]; then
	printInfo "Moving $userhome/.cache to $selectedPartition/cache/$username/"

	$EXEC_MV "$userhome"/.cache/* "$selectedPartition/cache/$username/"
	$EXEC_RM -rf "$userhome"/.cache
	$EXEC_SYMLINK -o $username:$username "$userhome"/.cache "$selectedPartition/cache/$username"
fi

echo

exit 0
