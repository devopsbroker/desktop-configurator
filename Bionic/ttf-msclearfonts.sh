#!/bin/bash

#
# ttf-msclearfonts.sh - DevOpsBroker script for installing Microsoft ClearType fonts
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
# The Microsoft ClearType Fonts include:
#   o Calibri
#   o Cambria
#   o Consolas
#   o Constantia
#   o Corbel
#
# This script will also install the following fonts, if available:
#   o Segoe UI
#   o Tahoma
#
# The best place to source Microsoft ClearType Fonts is from a Windows machine
# at C:\Windows\Fonts
#
# All Microsoft ClearType fonts are installed on Ubuntu Desktop 18.04 under the
# /usr/local/share/fonts directory
#
# Useful Linux Command-Line Utilities
# ¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯
# o Reload Font Cache
# fc-cache -f -v
#
# o List available fonts
# fc-list
#
# o View font matching
# fc-match -v Calibri
#
# TODO: http://manpages.ubuntu.com/manpages/bionic/man1/yad.1.html
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

## Script information
SCRIPT_EXEC=$( $EXEC_BASENAME "$BASH_SOURCE" )

# Display error if not running as root
if [ "$USER" !=  'root' ]; then
	printError "$SCRIPT_EXEC" 'Permission denied (you must be root)'
	exit 1
fi

################################## Variables ##################################

## Bash exec variables
EXEC_FONT_CACHE=/usr/bin/fc-cache
EXEC_YAD=/usr/bin/yad

# Variables
installedFont=false
TTF_UID=${SUDO_UID:-"$PKEXEC_UID"}
USER_HOME=$($EXEC_GETENT passwd $TTF_UID | $EXEC_CUT -d: -f6)

################################### Actions ###################################

# Clear screen only if called from command line
if [ $SHLVL -eq 1 ]; then
	clear
fi

printBox "DevOpsBroker $UBUNTU_RELEASE Microsoft ClearType Fonts Installer" 'true'

if [ ! -d /usr/share/fonts/truetype/mscleartype ]; then
	printInfo 'Creating /usr/share/fonts/truetype/mscleartype directory'

	$EXEC_MKDIR --parents --mode=0755 /usr/share/fonts/truetype/mscleartype
fi

printInfo 'Select directory containing the Microsoft ClearType Fonts to install'
sourceDir=$($EXEC_YAD --file-selection --directory --title='Microsoft ClearType Fonts' --width=800 --height=600 --center --filename=$USER_HOME/)
echo

# Install Calibri
if [ -f "$sourceDir"/calibri.ttf ]; then
	printInfo 'Installing Calibri'

	$EXEC_INSTALL -o root -g root -m 644 "$sourceDir"/calibri*.ttf /usr/share/fonts/truetype/mscleartype
	installedFont=true
fi

# Install Cambria
if [ -f "$sourceDir"/cambria.ttc ]; then
	printInfo 'Installing Cambria'

	$EXEC_INSTALL -o root -g root -m 644 "$sourceDir"/cambria*.tt* /usr/share/fonts/truetype/mscleartype
	installedFont=true
fi

# Install Consolas
if [ -f "$sourceDir"/consola.ttf ]; then
	printInfo 'Installing Consolas'

	$EXEC_INSTALL -o root -g root -m 644 "$sourceDir"/consola*.ttf /usr/share/fonts/truetype/mscleartype
	installedFont=true
fi

# Install Constantia
if [ -f "$sourceDir"/constan.ttf ]; then
	printInfo 'Installing Constantia'

	$EXEC_INSTALL -o root -g root -m 644 "$sourceDir"/constan*.ttf /usr/share/fonts/truetype/mscleartype
	installedFont=true
fi

# Install Corbel
if [ -f "$sourceDir"/corbel.ttf ]; then
	printInfo 'Installing Corbel'

	$EXEC_INSTALL -o root -g root -m 644 "$sourceDir"/corbel*.ttf /usr/share/fonts/truetype/mscleartype
	installedFont=true
fi

# Install Segoe UI
if [ -f "$sourceDir"/segoeui.ttf ]; then
	printInfo 'Installing Segoe UI'

	$EXEC_INSTALL -o root -g root -m 644 "$sourceDir"/segoeui*.ttf /usr/share/fonts/truetype/mscleartype
	installedFont=true
fi

# Install Tahoma
if [ -f "$sourceDir"/tahoma.ttf ]; then
	printInfo 'Installing Tahoma'

	$EXEC_INSTALL -o root -g root -m 644 "$sourceDir"/tahoma*.ttf /usr/share/fonts/truetype/mscleartype
	installedFont=true
fi

if [ "$installedFont" == 'true' ]; then
	echo
	printInfo 'Updating the font cache'

	$EXEC_FONT_CACHE -f -v
fi

echo 'Done!'

exit 0
