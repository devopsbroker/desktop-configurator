#!/bin/bash

#
# install.sh - DevOpsBroker Ubuntu 18.04 Desktop Configurator install script
#
# Copyright (C) 2018-2019 Edward Smith <edwardsmith@devopsbroker.org>
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
# Developed on Ubuntu 18.04.1 LTS running kernel.osrelease = 4.15.0-36
#
# To run this script:
#   o chmod u+x install.sh
#   o sudo ./install.sh
# -----------------------------------------------------------------------------
#

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ Preprocessing ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

## Script information
SCRIPT_DIR=$( /usr/bin/dirname "$BASH_SOURCE" )

# Load $SCRIPT_DIR/etc/devops/ansi.conf
source "$SCRIPT_DIR/etc/devops/ansi.conf"

# Load $SCRIPT_DIR/etc/devops/exec.conf
source "$SCRIPT_DIR/etc/devops/exec.conf"

# Load $SCRIPT_DIR/etc/devops/functions.conf
source "$SCRIPT_DIR/etc/devops/functions.conf"

# Load $SCRIPT_DIR/etc/devops/functions-admin.conf
source "$SCRIPT_DIR/etc/devops/functions-admin.conf"

# Load $SCRIPT_DIR/etc/devops/functions-io.conf
source "$SCRIPT_DIR/etc/devops/functions-io.conf"

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ Robustness ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

set -o errexit                 # Exit if any statement returns a non-true value
set -o nounset                 # Exit if use an uninitialised variable
set -o pipefail                # Exit if any statement in a pipeline returns a non-true value
IFS=$'\n\t'                    # Default the Internal Field Separator to newline and tab

scriptName='install.sh'

# Display error if not running as root
if [ "$USER" != 'root' ]; then
	printError $scriptName 'Permission denied (you must be root)'
	exit 1
fi

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~ Ubuntu Version Check ~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# Check which version of Ubuntu is installed
IS_DESKTOP="$(/usr/bin/dpkg -l gnome-shell 2>&1 | /bin/grep -c ^ii || true)"

# Display error if not running on Ubuntu Desktop
if [ $IS_DESKTOP -eq 0 ]; then
	printError $scriptName "Invalid Ubuntu version: Not Ubuntu Desktop"
	exit 1
fi

################################## Functions ##################################

# ¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯
# Function:     createSymlink
# Description:  Creates a symbolic link to the specified file
#
# Parameter $1: The name of the symbolic link to create
# Parameter $2: The target file to link to
# -----------------------------------------------------------------------------
function createSymlink() {
	local symlink="$1"
	local targetFile="$2"

	if [ ! -L "$symlink" ]; then
		printInfo "Creating symbolic link $symlink"
		$EXEC_LN -s "$targetFile" "$symlink"

		if [[ "$symlink" == /usr/local/sbin* ]]; then
			$EXEC_CHOWN --changes --no-dereference root:devops "$symlink"
		elif [[ "$symlink" == /usr/local/bin* ]]; then
			$EXEC_CHOWN --changes --no-dereference root:users "$symlink"
		fi
	fi
}

################################## Variables ##################################

## Variables
INSTALL_DIR=/opt/devopsbroker/bionic/desktop/configurator

################################### Actions ###################################

# Clear screen only if called from command line
if [ $SHLVL -eq 1 ]; then
	clear
fi

printBox "DevOpsBroker $UBUNTU_RELEASE Configurator Installer" 'true'

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ Initialization ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

devopsGroup="$($EXEC_GETENT group devops)"

# Add devops group
if [ -z "$devopsGroup" ]; then
	printInfo 'Adding devops group'
	$EXEC_ADDGROUP 'devops'
	echo
fi

# Add user to devops group, if necessary
if [ -z "$devopsGroup" ] || [ $(echo "$devopsGroup" | $EXEC_GREP -Fc $SUDO_USER || true ) -eq 0 ]; then
	printInfo "Adding $SUDO_USER to the 'devops' group"
	$EXEC_ADDUSER $SUDO_USER 'devops'
	echo
fi

# Create /cache directory for user cache
if [ ! -d /cache ]; then
	printInfo 'Creating /cache directory'

	$EXEC_MKDIR --parents --mode=0755 /cache
	$EXEC_CHOWN --changes root:users /cache
fi

# Create /opt/devopsbroker/bionic/desktop/configurator directory
if [ ! -d $INSTALL_DIR ]; then
	printInfo "Creating $INSTALL_DIR directory"

	$EXEC_MKDIR --parents --mode=2755 $INSTALL_DIR
	$EXEC_CHOWN --changes -R root:devops /opt/devopsbroker
fi

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ Installation ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# Copy files into the /opt/devopsbroker/bionic/desktop/configurator directory
printBanner "Copying files to $INSTALL_DIR/"

/bin/cp -uv --preserve=timestamps "$SCRIPT_DIR/configure-desktop.sh" "$INSTALL_DIR"
/bin/cp -uv --preserve=timestamps "$SCRIPT_DIR/device-drivers.sh" "$INSTALL_DIR"
/bin/cp -uv --preserve=timestamps "$SCRIPT_DIR/ttf-msclearfonts.sh" "$INSTALL_DIR"
/bin/cp -uv --preserve=timestamps "$SCRIPT_DIR/update-utils.sh" "$INSTALL_DIR"

/bin/cp -ruv --preserve=timestamps "$SCRIPT_DIR/archives" "$INSTALL_DIR"
/bin/cp -ruv --preserve=timestamps "$SCRIPT_DIR/doc" "$INSTALL_DIR"
/bin/cp -ruv --preserve=timestamps "$SCRIPT_DIR/etc" "$INSTALL_DIR"
/bin/cp -ruv --preserve=timestamps "$SCRIPT_DIR/home" "$INSTALL_DIR"
/bin/cp -ruv --preserve=timestamps "$SCRIPT_DIR/perf" "$INSTALL_DIR"
/bin/cp -ruvL --preserve=timestamps "$SCRIPT_DIR/usr" "$INSTALL_DIR"

echo
$EXEC_FIND "$INSTALL_DIR"/ -type f \( ! -name "*.sh" ! -name "*.tpl" \) -exec $EXEC_CHMOD --changes 640 {} + 2>/dev/null || true
echo
$EXEC_FIND "$INSTALL_DIR"/ -type f \( -name "*.sh" -o -name "*.tpl" \) -exec $EXEC_CHMOD --changes 750 {} + 2>/dev/null || true
echo
$EXEC_CHOWN --changes -R root:devops "$INSTALL_DIR"/ 2>/dev/null || true
echo

# Copy scriptinfo to /usr/local/bin
CP_OUTPUT="$(/bin/cp -uv --preserve=timestamps "$INSTALL_DIR"/usr/local/bin/scriptinfo /usr/local/bin)"
if [ ! -z "$CP_OUTPUT" ]  ; then
	$EXEC_CHMOD --changes 755 /usr/local/bin/scriptinfo
	$EXEC_CHOWN --changes root:users /usr/local/bin/scriptinfo
fi

# Copy derivesubnet to /usr/local/bin
CP_OUTPUT="$(/bin/cp -uv --preserve=timestamps "$INSTALL_DIR"/usr/local/bin/derivesubnet /usr/local/bin)"
if [ ! -z "$CP_OUTPUT" ]  ; then
	$EXEC_CHMOD --changes 755 /usr/local/bin/derivesubnet
	$EXEC_CHOWN --changes root:users /usr/local/bin/derivesubnet
fi

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ Shell Scripts ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# Make symlink to configure-desktop.sh
createSymlink /usr/local/sbin/configure-desktop "$INSTALL_DIR"/configure-desktop.sh

# Make symlink to device-drivers.sh
createSymlink /usr/local/sbin/device-drivers "$INSTALL_DIR"/device-drivers.sh

# Make symlink to ttf-msclearfonts.sh
createSymlink /usr/local/sbin/ttf-msclearfonts "$INSTALL_DIR"/ttf-msclearfonts.sh

# Make symlink to update-utils.sh
createSymlink /usr/local/sbin/update-utils "$INSTALL_DIR"/update-utils.sh

# Make symlink to etc/configure-amdgpu.sh
createSymlink /usr/local/sbin/configure-amdgpu "$INSTALL_DIR"/etc/configure-amdgpu.sh

# Make symlink to etc/configure-fstab.sh
createSymlink /usr/local/sbin/configure-fstab "$INSTALL_DIR"/etc/configure-fstab.sh

# Make symlink to etc/configure-kernel.sh
createSymlink /usr/local/sbin/configure-kernel "$INSTALL_DIR"/etc/configure-kernel.sh

# Make symlink to etc/configure-nvidia.sh
createSymlink /usr/local/sbin/configure-nvidia "$INSTALL_DIR"/etc/configure-nvidia.sh

# Make symlink to etc/configure-system.sh
createSymlink /usr/local/sbin/configure-system "$INSTALL_DIR"/etc/configure-system.sh

# Make symlink to etc/apt/configure-apt-mirror.sh
createSymlink /usr/local/sbin/configure-apt-mirror "$INSTALL_DIR"/etc/apt/configure-apt-mirror.sh

# Make symlink to etc/default/configure-grub.sh
createSymlink /usr/local/sbin/configure-grub "$INSTALL_DIR"/etc/default/configure-grub.sh

# Make symlink to etc/network/ip6tables-desktop.sh
createSymlink /usr/local/sbin/ip6tables-desktop "$INSTALL_DIR"/etc/network/ip6tables-desktop.sh

# Make symlink to etc/network/iptables-desktop.sh
createSymlink /usr/local/sbin/iptables-desktop "$INSTALL_DIR"/etc/network/iptables-desktop.sh

# Make symlink to etc/NetworkManager/configure-nm.sh
createSymlink /usr/local/sbin/configure-nm "$INSTALL_DIR"/etc/NetworkManager/configure-nm.sh

# Make symlink to etc/samba/configure-samba.sh
createSymlink /usr/local/sbin/configure-samba "$INSTALL_DIR"/etc/samba/configure-samba.sh

# Make symlink to etc/security/configure-security.sh
createSymlink /usr/local/sbin/configure-security "$INSTALL_DIR"/etc/security/configure-security.sh

# Make symlink to etc/udev/configure-udev.sh
createSymlink /usr/local/sbin/configure-udev "$INSTALL_DIR"/etc/udev/configure-udev.sh

# Make symlink to etc/udev/rules.d/tune-diskio.tpl
createSymlink /usr/local/sbin/tune-diskio "$INSTALL_DIR"/etc/udev/rules.d/tune-diskio.tpl

# Make symlink to etc/unbound/configure-unbound.sh
createSymlink /usr/local/sbin/configure-unbound "$INSTALL_DIR"/etc/unbound/configure-unbound.sh

# Make symlink to home/configure-user.sh
createSymlink /usr/local/sbin/configure-user "$INSTALL_DIR"/home/configure-user.sh

# Create /etc/devops directory
if [ ! -d /etc/devops ]; then
	printInfo 'Creating /etc/devops directory'
	$EXEC_MKDIR --parents --mode=0755 /etc/devops
fi

# Install /etc/devops/ansi.conf
installConfig 'ansi.conf' "$INSTALL_DIR/etc/devops" /etc/devops

# Install /etc/devops/exec.conf
installConfig 'exec.conf' "$INSTALL_DIR/etc/devops" /etc/devops

# Install /etc/devops/functions-admin.conf
installConfig 'functions-admin.conf' "$INSTALL_DIR/etc/devops" /etc/devops

# Install /etc/devops/functions-io.conf
installConfig 'functions-io.conf' "$INSTALL_DIR/etc/devops" /etc/devops

# Install /etc/devops/functions.conf
installConfig 'functions.conf' "$INSTALL_DIR/etc/devops" /etc/devops

echo

exit 0
