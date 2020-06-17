#
# makefile - DevOpsBroker makefile for Ubuntu 18.04 Desktop Configurator
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
# Developed on Ubuntu 18.04.1 LTS running kernel.osrelease = 4.15.0-38
#
# -----------------------------------------------------------------------------
#

################################### Includes ##################################

include /etc/devops/globals.mk

################################### Targets ###################################

.ONESHELL:
.PHONY: default test release printenv

default: test

test:
	@umask $(UMASK) && \
	source /etc/devops/ansi.conf && \
	$(MAKE) -f test.mk $(filter-out test,$(MAKECMDGOALS))

release:
	@umask $(UMASK) && \
	source /etc/devops/ansi.conf && \
	$(MAKE) -f release.mk $(filter-out release,$(MAKECMDGOALS))

printenv:
	@echo "MAKEFILE_LIST: $(MAKEFILE_LIST)"
	@echo "       TMPDIR: $(TMPDIR)"
	@echo "       CURDIR: $(CURDIR)"
	@echo
