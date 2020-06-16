#!/usr/bin/bash

#
# configure-nvidia.sh - DevOpsBroker script for configuring the NVIDIA graphics driver
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
# Developed on Ubuntu 18.04.2 LTS running kernel.osrelease = 4.18.0-16
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

# Load /etc/devops/functions-admin.conf if FUNC_ADMIN_CONFIG is unset
if [ -z "$FUNC_ADMIN_CONFIG" ] && [ -f /etc/devops/functions-admin.conf ]; then
	source /etc/devops/functions-admin.conf
fi

${FUNC_ADMIN_CONFIG?"[1;91mCannot load '/etc/devops/functions-admin.conf': No such file[0m"}

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
EXEC_ADD_APT_REPO=/usr/bin/add-apt-repository
EXEC_LSPCI=/usr/bin/lspci
EXEC_UPDATE_INITRAMFS=/usr/sbin/update-initramfs

################################### Actions ###################################

# Clear screen only if called from command line
if [ $SHLVL -eq 1 ]; then
	clear
fi

printBox "DevOpsBroker $UBUNTU_RELEASE NVIDIA Configurator" 'true'

#
# Check for an NVIDIA graphics card
#
hasNvidiaGPU="$( $EXEC_LSPCI | $EXEC_GREP -c VGA.*NVIDIA || true  )"

if [ $hasNvidiaGPU -eq 0 ]; then
	printNotice $SCRIPT_EXEC "This system does not have an NVIDIA GPU"
	exit 0
fi

#
# Add Graphics Drivers PPA
#
if [ ! -f /etc/apt/sources.list.d/graphics-drivers-ubuntu-ppa-bionic.list ]; then
	printBanner 'Adding Graphics Drivers PPA'

	$EXEC_ADD_APT_REPO -y ppa:graphics-drivers/ppa
	$EXEC_APT update
fi

#
# Install nvidia-driver-415
#
if [ ! -f "/usr/share/doc/nvidia-driver-415/copyright" ]; then
	printBanner 'Installing nvidia-driver-415'
	$EXEC_APT -y install nvidia-driver-415
fi

#
# Add Graphics Drivers PPA
#
if [ ! -f /etc/apt/sources.list.d/graphics-drivers-ubuntu-ppa-bionic.list ]; then
	printBanner 'Adding Graphics Drivers PPA'

	$EXEC_ADD_APT_REPO -y ppa:graphics-drivers/ppa
	$EXEC_APT update
fi

#
# Install ocl-icd-libopencl1
#
if [ ! -f "/usr/share/doc/ocl-icd-libopencl1/copyright" ]; then
	printBanner 'Installing Generic OpenCL ICD Loader'
	$EXEC_APT -y install ocl-icd-libopencl1
fi

# Install /etc/modprobe.d/nvidia.conf
installConfig 'nvidia.conf' "$SCRIPT_DIR"/modprobe.d /etc/modprobe.d

if [ "$INSTALL_CONFIG" == 'true' ]; then
	printBanner 'Updating initramfs'
	$EXEC_UPDATE_INITRAMFS -u
fi

exit 0
