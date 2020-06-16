#!/usr/bin/bash

#
# configure-amdgpu.sh - DevOpsBroker script for configuring the amdgpu graphics driver
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
# Developed on Ubuntu 16.04.5 LTS running kernel.osrelease = 4.15.0-36
#
# There are a number of issues with the installation of the AMDGPU-PRO drivers
# that this configuration script is meant to address:
#   o AMD does not provide a means of generating a sample xorg.conf file
#   o Configuration parameters for the amdgpu driver are decentralized across
#     multiple config files
#   o When you download / extract / execute amdgpu-pro-install, it actually
#     *does not update* the xorg libraries / modules / extensions accordingly
#   o The /opt/amdgpu-pro/bin/clinfo utility is not installed anywhere in the
#     user's PATH
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

## Script information
SCRIPT_INFO=( $($EXEC_SCRIPTINFO "$BASH_SOURCE") )
SCRIPT_DIR="${SCRIPT_INFO[0]}"
SCRIPT_EXEC="${SCRIPT_INFO[1]}"

# Display error if not running as root
if [ "$USER" != 'root' ]; then
	printError "$SCRIPT_EXEC" 'Permission denied (you must be root)'
	exit 1
fi

################################## Functions ##################################


################################## Variables ##################################

## Options

## Variables

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ OPTION Parsing ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

if [ ! -d '/opt/amdgpu' ] || [ ! -d '/opt/amdgpu-pro' ]; then
	echo "${bold}${yellow}Please download and install the AMDGPU-PRO drivers from amd.com"
	echo
	echo "${white}See ${purple}https://support.amd.com/en-us/kb-articles/Pages/AMDGPU-PRO-Install.aspx${white} for more information${reset}"
fi

################################### Actions ###################################

printBanner "Configuring AMDGPU-PRO driver"

# 1) Update /usr/lib/xorg/modules/libglamoregl.so
if [ -f '/opt/amdgpu/lib/xorg/modules/libglamoregl.so' ] && [ ! -L '/usr/lib/xorg/modules/libglamoregl.so' ]; then

	printInfo 'Backing up /usr/lib/xorg/modules/libglamoregl.so'
	$EXEC_CP -a /usr/lib/xorg/modules/libglamoregl.so /opt/amdgpu/lib/xorg/modules/libglamoregl.so.bak

	printInfo 'Linking to /opt/amdgpu/lib/xorg/modules/libglamoregl.so'
	$EXEC_LN -fs /opt/amdgpu/lib/xorg/modules/libglamoregl.so /usr/lib/xorg/modules/libglamoregl.so
fi

# 2) Update /usr/lib/xorg/modules/drivers/amdgpu_drv.so
if [ -f '/opt/amdgpu/lib/xorg/modules/drivers/amdgpu_drv.so' ] && [ ! -L '/usr/lib/xorg/modules/drivers/amdgpu_drv.so' ]; then

	printInfo 'Backing up /usr/lib/xorg/modules/drivers/amdgpu_drv.so'
	$EXEC_CP -a /usr/lib/xorg/modules/drivers/amdgpu_drv.so /opt/amdgpu/lib/xorg/modules/drivers/amdgpu_drv.so.bak

	printInfo 'Linking to /opt/amdgpu/lib/xorg/modules/libglamoregl.so'
	$EXEC_LN -fs /opt/amdgpu/lib/xorg/modules/drivers/amdgpu_drv.so /usr/lib/xorg/modules/drivers/amdgpu_drv.so
fi

# 3) Update /usr/lib/xorg/modules/extensions/libglx.so
if [ -f '/opt/amdgpu-pro/lib/xorg/modules/extensions/libglx.so' ] && [ ! -L '/usr/lib/xorg/modules/extensions/libglx.so' ]; then

	printInfo 'Backing up /usr/lib/xorg/modules/extensions/libglx.so'
	$EXEC_CP -a /usr/lib/xorg/modules/extensions/libglx.so /opt/amdgpu-pro/lib/xorg/modules/extensions/libglx.so.bak

	printInfo 'Linking to /opt/amdgpu-pro/lib/xorg/modules/extensions/libglx.so'
	$EXEC_LN -fs /opt/amdgpu-pro/lib/xorg/modules/extensions/libglx.so /usr/lib/xorg/modules/extensions/libglx.so
fi

# 4) Install /usr/local/bin/clinfo
if [ -f '/opt/amdgpu-pro/bin/clinfo' ] && [ ! -L '/usr/local/bin/clinfo' ]; then

	printInfo 'Linking to /opt/amdgpu-pro/bin/clinfo'
	$EXEC_LN -fs /opt/amdgpu-pro/bin/clinfo /usr/local/bin/clinfo
fi

# 5) Install /etc/amd/amdrc
if [ ! -f '/etc/amd/amdrc.orig' ]; then

	printInfo 'Installing /etc/amd/amdrc'
	$EXEC_INSTALL -b --suffix .orig -o root -g root -m 644 "$SCRIPT_DIR/amd/amdrc" /etc/amd
fi

# 6) Suggest using /etc/modprobe.d/amdgpu.conf
if [ ! -f /etc/modprobe.d/amdgpu.conf ]; then

	echo "${bold}${yellow}NOTE: ${white}Consider optimizing your AMD graphics card using the DevOpsBroker /etc/modprobe.d/amdgpu.conf file as a guide${reset}"
fi

# 7) Suggest using /etc/X11/xorg-amd.conf
if [ ! -f /etc/X11/xorg.conf ] || ! $EXEC_GREP -Eq 'Driver[[:space:]]+"amdgpu"' /etc/X11/xorg.conf; then

	echo "${bold}${yellow}NOTE: ${white}Consider optimizing your X11 configuration using the DevOpsBroker /etc/X11/xorg-amd.conf file as a guide${reset}"
fi

echo

exit 0
