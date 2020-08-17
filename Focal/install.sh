#!/usr/bin/bash

#
# install.sh - DevOpsBroker Ubuntu 18.04 Desktop Configurator install script
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
# Developed on Ubuntu 20.04 LTS running kernel.osrelease = 5.4.0-31
#
# To run this script:
#   o chmod u+x install.sh
#   o sudo ./install.sh
# -----------------------------------------------------------------------------
#

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ Preprocessing ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

#
# Load DevOpsBroker configuration files locally
#

SCRIPT_DIR=$( /usr/bin/dirname "$BASH_SOURCE" )

source "$SCRIPT_DIR/etc/devops/ansi.conf"
source "$SCRIPT_DIR/etc/devops/exec.conf"
source "$SCRIPT_DIR/etc/devops/functions.conf"
source "$SCRIPT_DIR/etc/devops/functions-admin.conf"
source "$SCRIPT_DIR/etc/devops/functions-io.conf"
source "$SCRIPT_DIR/etc/devops/functions-net.conf"

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
IS_DESKTOP="$(/usr/bin/dpkg -l gnome-shell 2>&1 | $EXEC_GREP -c ^ii || true)"

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
INSTALL_DIR=/opt/devopsbroker/focal/desktop/configurator

################################### Actions ###################################

# Clear screen only if called from command line
if [ $SHLVL -eq 1 ]; then
	clear
fi

printBox "DevOpsBroker $UBUNTU_RELEASE Configurator Installer" 'true'

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ Initialization ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

devopsGroup="$($EXEC_GETENT group devops || true)"

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

# Create /opt/devopsbroker/focal/desktop/configurator directory
if [ ! -d $INSTALL_DIR ]; then
	printInfo "Creating $INSTALL_DIR directory"

	$EXEC_MKDIR --parents --mode=2755 $INSTALL_DIR
	$EXEC_CHOWN --changes -R root:devops /opt/devopsbroker
fi

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ Installation ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# Copy files into the /opt/devopsbroker/focal/desktop/configurator directory
printBanner "Copying files to $INSTALL_DIR/"

$EXEC_CP -uv --preserve=timestamps "$SCRIPT_DIR/configure-desktop.sh" "$INSTALL_DIR"
$EXEC_CP -uv --preserve=timestamps "$SCRIPT_DIR/device-drivers.sh" "$INSTALL_DIR"
$EXEC_CP -uv --preserve=timestamps "$SCRIPT_DIR/ttf-msclearfonts.sh" "$INSTALL_DIR"
$EXEC_CP -uv --preserve=timestamps "$SCRIPT_DIR/update-utils.sh" "$INSTALL_DIR"

$EXEC_CP -ruv --preserve=timestamps "$SCRIPT_DIR/doc" "$INSTALL_DIR"
$EXEC_CP -ruv --preserve=timestamps "$SCRIPT_DIR/etc" "$INSTALL_DIR"
$EXEC_CP -ruv --preserve=timestamps "$SCRIPT_DIR/home" "$INSTALL_DIR"
$EXEC_CP -ruv --preserve=timestamps "$SCRIPT_DIR/perf" "$INSTALL_DIR"
$EXEC_CP -ruvL --preserve=timestamps "$SCRIPT_DIR/usr" "$INSTALL_DIR"

echo
$EXEC_FIND "$INSTALL_DIR"/ -type f \( ! -name "*.sh" ! -name "*.tpl" \) -exec $EXEC_CHMOD --changes 640 {} + 2>/dev/null || true
echo
$EXEC_FIND "$INSTALL_DIR"/ -type f \( -name "*.sh" -o -name "*.tpl" \) -exec $EXEC_CHMOD --changes 750 {} + 2>/dev/null || true
echo
$EXEC_CHOWN --changes -R root:devops "$INSTALL_DIR"/ 2>/dev/null || true
echo

# Copy scriptinfo to /usr/local/bin
CP_OUTPUT="$($EXEC_CP -uv --preserve=timestamps "$INSTALL_DIR"/usr/local/bin/scriptinfo /usr/local/bin)"
if [ ! -z "$CP_OUTPUT" ]  ; then
	$EXEC_CHMOD --changes 755 /usr/local/bin/scriptinfo
	$EXEC_CHOWN --changes root:users /usr/local/bin/scriptinfo
fi

# Copy derivesubnet to /usr/local/bin
CP_OUTPUT="$($EXEC_CP -uv --preserve=timestamps "$INSTALL_DIR"/usr/local/bin/derivesubnet /usr/local/bin)"
if [ ! -z "$CP_OUTPUT" ]  ; then
	$EXEC_CHMOD --changes 755 /usr/local/bin/derivesubnet
	$EXEC_CHOWN --changes root:users /usr/local/bin/derivesubnet
fi

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ Shell Scripts ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

#
# Create symlinks for DevOpsBroker configuration and administration scripts
#

createSymlink /usr/local/sbin/configure-desktop "$INSTALL_DIR"/configure-desktop.sh
createSymlink /usr/local/sbin/device-drivers "$INSTALL_DIR"/device-drivers.sh
createSymlink /usr/local/sbin/ttf-msclearfonts "$INSTALL_DIR"/ttf-msclearfonts.sh
createSymlink /usr/local/sbin/update-utils "$INSTALL_DIR"/update-utils.sh
createSymlink /usr/local/sbin/configure-amdgpu "$INSTALL_DIR"/etc/configure-amdgpu.sh
createSymlink /usr/local/sbin/configure-fstab "$INSTALL_DIR"/etc/configure-fstab.sh
createSymlink /usr/local/sbin/configure-kernel "$INSTALL_DIR"/etc/configure-kernel.sh
createSymlink /usr/local/sbin/configure-nvidia "$INSTALL_DIR"/etc/configure-nvidia.sh
createSymlink /usr/local/sbin/configure-system "$INSTALL_DIR"/etc/configure-system.sh
createSymlink /usr/local/sbin/configure-apt-mirror "$INSTALL_DIR"/etc/apt/configure-apt-mirror.sh
createSymlink /usr/local/sbin/configure-grub "$INSTALL_DIR"/etc/default/configure-grub.sh
createSymlink /usr/local/sbin/configure-nm "$INSTALL_DIR"/etc/NetworkManager/configure-nm.sh
createSymlink /usr/local/sbin/configure-nftables "$INSTALL_DIR"/etc/nftables/configure-nftables.sh
createSymlink /usr/local/sbin/nftables-private "$INSTALL_DIR"/etc/nftables/nftables-private.sh
createSymlink /usr/local/sbin/nftables-public "$INSTALL_DIR"/etc/nftables/nftables-public.sh
createSymlink /usr/local/sbin/configure-samba "$INSTALL_DIR"/etc/samba/configure-samba.sh
createSymlink /usr/local/sbin/configure-security "$INSTALL_DIR"/etc/security/configure-security.sh
createSymlink /usr/local/sbin/configure-udev "$INSTALL_DIR"/etc/udev/configure-udev.sh
createSymlink /usr/local/sbin/tune-diskio "$INSTALL_DIR"/etc/udev/rules.d/tune-diskio.tpl
createSymlink /usr/local/sbin/configure-resolved "$INSTALL_DIR"/etc/systemd/configure-resolved.sh
createSymlink /usr/local/sbin/configure-cache "$INSTALL_DIR"/home/configure-cache.sh
createSymlink /usr/local/sbin/configure-user "$INSTALL_DIR"/home/configure-user.sh
createSymlink /usr/local/sbin/configure-ssh "$INSTALL_DIR"/home/configure-ssh.sh

#
# Install DevOpsBroker configuration files
#

if [ ! -d /etc/devops ]; then
	printInfo 'Creating /etc/devops directory'
	$EXEC_MKDIR --parents --mode=0755 /etc/devops
fi

echo

installConfig 'ansi.conf' "$INSTALL_DIR/etc/devops" /etc/devops
installConfig 'exec.conf' "$INSTALL_DIR/etc/devops" /etc/devops
installConfig 'functions-admin.conf' "$INSTALL_DIR/etc/devops" /etc/devops
installConfig 'functions-io.conf' "$INSTALL_DIR/etc/devops" /etc/devops
installConfig 'functions-net.conf' "$INSTALL_DIR/etc/devops" /etc/devops
installConfig 'functions.conf' "$INSTALL_DIR/etc/devops" /etc/devops

exit 0
