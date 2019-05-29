#!/bin/bash

#
# sources-list.tpl - DevOpsBroker script for generating /etc/apt/sources.list
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
# Parameters:
#   o $1: The name of the mirror to configure /etc/apt/sources.list with
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

# Display error if not running as root
if [ "$USER" != 'root' ]; then
	printError 'sources-list.tpl' 'Permission denied (you must be root)'
	exit 1
fi

################################## Variables ##################################

## Options
aptMirrorSite=${1:-}

## Variables
YEAR=$($EXEC_DATE +'%Y')

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ OPTION Parsing ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# Display usage if no parameters given
if [ -z "$aptMirrorSite" ]; then
	printUsage 'sources-list.tpl APT_MIRROR_SITE'
	exit 1
fi

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ Template ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# Backup original /etc/apt/sources.list
if [ ! -f /etc/apt/sources.list.orig ]; then
	$EXEC_CP /etc/apt/sources.list /etc/apt/sources.list.orig
fi

## Template variables

origHeader=$($EXEC_HEAD -1 /etc/apt/sources.list.orig)

## Template
cat << EOF
#
# sources.list - DevOpsBroker configuration for /etc/apt/sources.list
#
# Copyright (C) $YEAR Edward Smith <edwardsmith@devopsbroker.org>
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
$origHeader
# -----------------------------------------------------------------------------
#

deb $aptMirrorSite bionic main restricted
# deb-src $aptMirrorSite bionic main restricted

# Major bug fix updates produced after the final release of the distribution
deb $aptMirrorSite bionic-updates main restricted
# deb-src $aptMirrorSite bionic-updates main restricted

# Entirely unsupported software by the Ubuntu team
deb $aptMirrorSite bionic universe
# deb-src $aptMirrorSite bionic universe
deb $aptMirrorSite bionic-updates universe
# deb-src $aptMirrorSite bionic-updates universe

# Entirely unsupported software by the Ubuntu team and may not be under a free
# license
deb $aptMirrorSite bionic multiverse
# deb-src $aptMirrorSite bionic multiverse
deb $aptMirrorSite bionic-updates multiverse
# deb-src $aptMirrorSite bionic-updates multiverse

# Includes newer versions of some applications, though may not have been tested
# as extensively as in the main release
deb $aptMirrorSite bionic-backports main restricted universe multiverse
# deb-src $aptMirrorSite bionic-backports main restricted universe multiverse

# Uncomment the following two lines to add software from Canonical's
# 'partner' repository
# deb $aptMirrorSite bionic partner
# deb-src $aptMirrorSite bionic partner

deb $aptMirrorSite bionic-security main restricted
# deb-src $aptMirrorSite bionic-security main restricted
deb $aptMirrorSite bionic-security universe
# deb-src $aptMirrorSite bionic-security universe
deb $aptMirrorSite bionic-security multiverse
# deb-src $aptMirrorSite bionic-security multiverse

EOF

exit 0
