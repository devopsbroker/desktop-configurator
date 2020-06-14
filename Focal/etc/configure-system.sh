#!/bin/bash

#
# configure-system.sh - DevOpsBroker script for systemwide configurations
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
# Developed on Ubuntu 16.04.4 LTS running kernel.osrelease = 4.13.0-43
#
# The following systemwide initialization files are configured by this script:
#
# o /etc/adduser.conf
# o /etc/bash.bashrc
# o /etc/modules
# o /etc/ntp.conf
# o /etc/profile
# o /etc/tidy.conf
# o /etc/apparmor.d/local/usr.bin.evince
# o /etc/bash_completion.d/*
# o /etc/default/resolvconf
# o /etc/devops/ansi.conf
# o /etc/devops/exec.conf
# o /etc/devops/functions.conf
# o /etc/devops/functions-admin.conf
# o /etc/devops/functions-io.conf
# o /etc/devops/globals.mk
# o /etc/modprobe.d/kvm-amd.conf
# o /etc/modprobe.d/nf_conntrack.conf
# o /etc/network/interfaces
# o /etc/pam.d/common-session
# o /etc/ssl/ca.conf
# o /etc/ssl/req.conf
# o /etc/sudoers.d/10-umask
# o /etc/sudoers.d/20-env_keep
# o /etc/sysctl.d/40-ipv6-enable.conf
# o /etc/vim/vimrc.local
#
# Other configuration tasks include:
# o Disable root login
# o Fix Default Applications for Common MIME Types
# o Show Hidden Startup Applications
#
# Useful Linux Command-Line Utilities
# ¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯
# Print all or part of the Bash shell environment
#   o printenv
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

################################## Variables ##################################

## Bash exec variables
EXEC_LSCPU=/usr/bin/lscpu
EXEC_LSMOD=/sbin/lsmod
EXEC_LSPCI=/usr/bin/lspci
EXEC_PASSWD=/usr/bin/passwd
EXEC_UPDATE_INITRAMFS=/usr/sbin/update-initramfs

## Variables
export TMPDIR=${TMPDIR:-'/tmp'}
echoOnExit=false
updateInitramfs=false
vgaDevice=$($EXEC_LSPCI | $EXEC_GREP -F --max-count 1 'VGA' || true)

################################### Actions ###################################

# Clear screen only if called from command line
if [ $SHLVL -eq 1 ]; then
	clear
fi

printBox "DevOpsBroker $UBUNTU_RELEASE System Configurator" 'true'

# Install /etc/adduser.conf
installConfig 'adduser.conf' "$SCRIPT_DIR" /etc

# Install /etc/bash.bashrc
installConfig 'bash.bashrc' "$SCRIPT_DIR" /etc

# Install /etc/modules
installConfig 'modules' "$SCRIPT_DIR" /etc

if [ "$INSTALL_CONFIG" == 'true' ]; then
	updateInitramfs=true
fi

# Install /etc/ntp.conf
installConfig 'ntp.conf' "$SCRIPT_DIR" /etc 'ntp'

# Install /etc/profile
installConfig 'profile' "$SCRIPT_DIR" /etc

# Install /etc/tidy.conf
installConfig 'tidy.conf' "$SCRIPT_DIR" /etc

# Install /etc/apparmor.d/local/usr.bin.evince
installConfig 'usr.bin.evince' "$SCRIPT_DIR"/apparmor.d/local /etc/apparmor.d/local

# Install /etc/bash_completion.d/*
$EXEC_CP -uv "$SCRIPT_DIR"/bash_completion.d/* /etc/bash_completion.d
$EXEC_CHMOD --changes 644 /etc/bash_completion.d/*

# Install /etc/default/resolvconf
installConfig 'resolvconf' "$SCRIPT_DIR"/default /etc/default

if [ -d "$SCRIPT_DIR"/devops ]; then
	# Install /etc/devops/ansi.conf
	installConfig 'ansi.conf' "$SCRIPT_DIR/devops" /etc/devops

	# Install /etc/devops/exec.conf
	installConfig 'exec.conf' "$SCRIPT_DIR/devops" /etc/devops

	# Install /etc/devops/functions.conf
	installConfig 'functions.conf' "$SCRIPT_DIR/devops" /etc/devops

	# Install /etc/devops/functions-admin.conf
	installConfig 'functions-admin.conf' "$SCRIPT_DIR/devops" /etc/devops

	# Install /etc/devops/functions-io.conf
	installConfig 'functions-io.conf' "$SCRIPT_DIR/devops" /etc/devops

	# Install /etc/devops/globals.mk
	installConfig 'globals.mk' "$SCRIPT_DIR/devops" /etc/devops
fi

# Install /etc/modprobe.d/kvm-amd.conf
if $EXEC_LSMOD | $EXEC_GREP -Eq '^kvm\b' && $EXEC_LSCPU | $EXEC_GREP -q 'AMD'; then
	installConfig 'kvm-amd.conf' "$SCRIPT_DIR"/modprobe.d /etc/modprobe.d

	if [ "$INSTALL_CONFIG" == 'true' ]; then
		updateInitramfs=true
	fi
fi

# Install /etc/modprobe.d/nf_conntrack.conf
installConfig 'nf_conntrack.conf' "$SCRIPT_DIR"/modprobe.d /etc/modprobe.d

if [ "$INSTALL_CONFIG" == 'true' ]; then
	updateInitramfs=true
fi

# Configure /etc/network/interfaces
if ! $EXEC_GREP -Fq 'iface lo inet6 loopback' /etc/network/interfaces; then
	printInfo 'Configuring /etc/network/interfaces'

	echo 'iface lo inet6 loopback' >> /etc/network/interfaces

	echoOnExit=true
fi

# Install /etc/pam.d/common-session
installConfig 'common-session' "$SCRIPT_DIR"/pam.d /etc/pam.d

# Install /etc/ssl/ca.conf
installConfig 'ca.conf' "$SCRIPT_DIR"/ssl /etc/ssl

# Install /etc/ssl/req.conf
installConfig 'req.conf' "$SCRIPT_DIR"/ssl /etc/ssl

# Install /etc/sudoers.d/10-umask
if [ ! -f /etc/sudoers.d/10-umask ] || \
		[ "$SCRIPT_DIR"/sudoers.d/10-umask -nt /etc/sudoers.d/10-umask ]; then
	printInfo 'Installing /etc/sudoers.d/10-umask'

	# Install as root:root with r--r----- privileges
	$EXEC_INSTALL -o root -g root -m 440 "$SCRIPT_DIR"/sudoers.d/10-umask /etc/sudoers.d

	echoOnExit=true
fi

# Install /etc/sudoers.d/20-env_keep
if [ ! -f /etc/sudoers.d/20-env_keep ] || \
		[ "$SCRIPT_DIR"/sudoers.d/20-env_keep -nt /etc/sudoers.d/20-env_keep ]; then
	printInfo 'Installing /etc/sudoers.d/20-env_keep'

	# Install as root:root with r--r----- privileges
	$EXEC_INSTALL -o root -g root -m 440 "$SCRIPT_DIR"/sudoers.d/20-env_keep /etc/sudoers.d
	echoOnExit=true
fi

# Install /etc/sysctl.d/40-ipv6-enable.conf
installConfig '40-ipv6-enable.conf' "$SCRIPT_DIR"/sysctl.d /etc/sysctl.d

# Install /etc/vim/vimrc.local
installConfig 'vimrc.local' "$SCRIPT_DIR"/vim /etc/vim

#
# Disable root login
#

if [[ $($EXEC_PASSWD -S root) != "root L"* ]]; then
	printInfo 'Disabling root login'

	$EXEC_PASSWD -l root

	echoOnExit=true
fi

#
# X11 Configuration
#

regExpr="\\bNVIDIA\\b"
if [[ "$vgaDevice" =~ $regExpr ]]; then

	if [ ! -f /etc/modprobe.d/nvidia.conf ]; then
		echo
		echo "${bold}${yellow}NOTE: ${white}Consider optimizing your NVidia graphics card using the DevOpsBroker /etc/modprobe.d/nvidia.conf file as a guide${reset}"
		echoOnExit=true
	fi

	# Suggest using /etc/X11/xorg-nvidia.conf
	if [ ! -f /etc/X11/xorg.conf ]; then
		echo
		echo "${bold}${yellow}NOTE: ${white}Consider optimizing your X11 configuration using the DevOpsBroker /etc/X11/xorg-nvidia.conf file as a guide${reset}"
		echoOnExit=true
	fi
elif [[ "$vgaDevice" =~ (AMD|ATI) ]]; then

	if [ ! -f /etc/modprobe.d/amdgpu.conf ]; then
		echo
		echo "${bold}${yellow}NOTE: ${white}Consider optimizing your AMD graphics card using the DevOpsBroker /etc/modprobe.d/amdgpu.conf file as a guide${reset}"
		echoOnExit=true
	fi

	# Suggest using /etc/X11/xorg-amd.conf
	if [ ! -f /etc/X11/xorg.conf ] || ! $EXEC_GREP -Eq 'Driver[[:space:]]+"amdgpu"' /etc/X11/xorg.conf; then
		echo
		echo "${bold}${yellow}NOTE: ${white}Consider optimizing your X11 configuration using the DevOpsBroker /etc/X11/xorg-amd.conf file as a guide${reset}"
		echoOnExit=true
	fi
fi

#
# Fix Default Applications for Common MIME Types
#

if $EXEC_GREP -Eq '^audio/.+=org\.gnome\.Totem\.desktop' /usr/share/applications/defaults.list; then

	printInfo 'Changing default application for all audio files to Audacious'

	# Fix /usr/share/applications/defaults.list audio defaults
	$EXEC_SED --regexp-extended -i 's/^(audio\/.+=)org\.gnome\.Totem\.desktop/\1audacious.desktop/' /usr/share/applications/defaults.list

	# Fix /etc/gnome/defaults.list audio defaults
	$EXEC_SED --regexp-extended -i 's/^(audio\/.+=)org\.gnome\.Totem\.desktop/\1audacious.desktop/' /etc/gnome/defaults.list

	printInfo 'Changing default application for all video files to VLC'

	# Fix /usr/share/applications/defaults.list video defaults
	$EXEC_SED --regexp-extended -i 's/^(video\/.+=)org\.gnome\.Totem\.desktop/\1vlc.desktop/' /usr/share/applications/defaults.list

	# Fix /etc/gnome/defaults.list video defaults
	$EXEC_SED --regexp-extended -i 's/^(video\/.+=)org\.gnome\.Totem\.desktop/\1vlc.desktop/' /etc/gnome/defaults.list

	echoOnExit=true
fi

#
# Show Hidden Startup Applications
#   o Ubuntu Search -> Startup Applications
#

if $EXEC_GREP -Fq 'NoDisplay=true' /etc/xdg/autostart/*.desktop; then
	printInfo 'Show hidden startup applications under Ubuntu Search -> Startup Applications'

	$EXEC_SED --regexp-extended -i 's/NoDisplay=true/NoDisplay=false/g' /etc/xdg/autostart/*.desktop

	echoOnExit=true
fi

if [ "$updateInitramfs" == 'true' ]; then
	printInfo 'Updating initramfs'
	$EXEC_UPDATE_INITRAMFS -u
fi

if [ "$echoOnExit" == 'true' ]; then
	echo
fi

exit 0
