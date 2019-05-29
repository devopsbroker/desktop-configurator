#!/bin/bash

#
# build-tidy.sh - DevOpsBroker script for building HTML Tidy from source
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
# Developed on Ubuntu 16.04.5 LTS running kernel.osrelease = 4.15.0-33
#
# mkdir /mnt/ssd/build
# chmod 775 /mnt/ssd/build
# chown root:users /mnt/ssd/build
#
# mkdir /mnt/ssd/repo
# chmod 775 /mnt/ssd/repo
# chown root:users /mnt/ssd/repo
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

# Display error if not running as root
if [ "$USER" != 'root' ]; then
	printError 'build-tidy.sh' 'Permission denied (you must be root)'
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
  if [ ! -f "$1" ]; then
    printBanner "Installing $2"

    $EXEC_APT -y install $2

    echo
  fi
}

################################## Variables ##################################

## Bash exec variables
EXEC_CMAKE=/usr/bin/cmake
EXEC_GIT=/usr/bin/git
EXEC_MAKE=/usr/bin/make

## Options

## Variables
DIR_GIT_REPO=/mnt/ssd/repo
DIR_BUILD=/mnt/ssd/build

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ Build Dependencies ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# Install cmake
installPackage '/usr/bin/cmake' 'cmake'

# Install xsltproc
installPackage '/usr/bin/xsltproc' 'xsltproc'

################################### Actions ###################################

# 1) Build Tidy
cd "$DIR_BUILD"/tidy-html5-5.6.0/build/cmake
$EXEC_CMAKE ../.. -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/usr

# 2) Make the Tidy .deb package
$EXEC_MAKE package

exit 0

