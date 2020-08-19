#
# release.mk - DevOpsBroker makefile for creating a .deb package of Ubuntu 18.04 Desktop Configurator
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

################################## Variables ##################################

PKG_NAME := desktop-configurator
VERSION := 2.2.0
ARCH := amd64
PKG_ARCHIVE := $(PKG_NAME)_$(VERSION)_$(ARCH)

BUILD_DIR := $(TMPDIR)/$(PKG_ARCHIVE)
APPLICATION_DIR = $(realpath $(CURDIR)/..)
RELEASE_DIR := $(CURDIR)/pkg-debian

INSTALL_DIR := /opt/devopsbroker/focal/desktop/configurator

EXEC_CHMOD := $(shell which chmod)
EXEC_CHOWN := $(shell which chown)
EXEC_CP := $(shell which cp) --preserve=timestamps
EXEC_FIND := $(shell which find)
EXEC_GZIP := $(shell which gzip)
EXEC_LN := $(shell which ln)
EXEC_MKDIR := $(shell which mkdir)
EXEC_MV := $(shell which mv)
EXEC_RM := $(shell which rm)

################################### Targets ###################################

.ONESHELL:
.SILENT:
.PHONY: default clean createdirs copyfiles copybase copyetc copyhome copyperf \
	copyusr configdocs installutils applysecurity package printenv

default: package

clean:
	echo
	$(call printInfo,Cleaning existing release artifacts)
	$(EXEC_RM) -rf $(BUILD_DIR)
	$(EXEC_RM) -f $(TMPDIR)/$(PKG_ARCHIVE).deb
	$(EXEC_RM) -rf $(RELEASE_DIR)

createdirs: clean
	echo
	$(call printInfo,Creating $(RELEASE_DIR) directory)
	$(EXEC_MKDIR) -p --mode=0750 $(RELEASE_DIR)

	$(call printInfo,Creating $(BUILD_DIR) directory)
	$(EXEC_MKDIR) -p --mode=0755 $(BUILD_DIR)

	$(call printInfo,Creating $(BUILD_DIR)/DEBIAN directory)
	$(EXEC_MKDIR) -p --mode=0755 $(BUILD_DIR)/DEBIAN

	$(call printInfo,Creating /cache directory)
	$(EXEC_MKDIR) -p --mode=0755 $(BUILD_DIR)/cache
	$(EXEC_CHOWN) root:users $(BUILD_DIR)/cache

	$(call printInfo,Creating /etc directory)
	$(EXEC_MKDIR) -p --mode=0755 $(BUILD_DIR)/etc

	$(call printInfo,Creating /usr/share directory)
	$(EXEC_MKDIR) -p --mode=0755 $(BUILD_DIR)/usr/share

	$(call printInfo,Creating $(INSTALL_DIR) directory)
	$(EXEC_MKDIR) -p $(BUILD_DIR)/$(INSTALL_DIR)

	$(call printInfo,Creating $(INSTALL_DIR)/archives directory)
	$(EXEC_MKDIR) -p $(BUILD_DIR)/$(INSTALL_DIR)/archives

	$(call printInfo,Setting directory permissions to 2750 and ownership to root:devops)
	$(EXEC_CHMOD) -R 2750 $(BUILD_DIR)/opt/devopsbroker
	$(EXEC_CHMOD) 0755 $(BUILD_DIR)/opt
	$(EXEC_CHOWN) -R root:devops $(BUILD_DIR)/opt/devopsbroker
	echo

copybase: createdirs
	$(call printInfo,Copying configure-desktop.sh to $(INSTALL_DIR))
	$(EXEC_CP) $(APPLICATION_DIR)/configure-desktop.sh $(BUILD_DIR)/$(INSTALL_DIR)

	$(call printInfo,Copying device-drivers.sh to $(INSTALL_DIR))
	$(EXEC_CP) $(APPLICATION_DIR)/device-drivers.sh $(BUILD_DIR)/$(INSTALL_DIR)

	$(call printInfo,Copying ttf-msclearfonts.sh to $(INSTALL_DIR))
	$(EXEC_CP) $(APPLICATION_DIR)/ttf-msclearfonts.sh $(BUILD_DIR)/$(INSTALL_DIR)

	$(call printInfo,Copying archives/tidy-5.6.0-64bit.deb to $(INSTALL_DIR)/archives)
	$(EXEC_CP) $(APPLICATION_DIR)/archives/tidy-5.6.0-64bit.deb $(BUILD_DIR)/$(INSTALL_DIR)/archives

copyetc: createdirs
	$(call printInfo,Copying etc/ files to $(INSTALL_DIR)/etc)
	$(EXEC_CP) -r $(APPLICATION_DIR)/etc $(BUILD_DIR)/$(INSTALL_DIR)

	$(call printInfo,Installing /etc/devops directory)
	$(EXEC_MV) $(BUILD_DIR)/$(INSTALL_DIR)/etc/devops $(BUILD_DIR)/etc

copyhome: createdirs
	$(call printInfo,Copying home/ files to $(INSTALL_DIR)/home)
	$(EXEC_CP) -r $(APPLICATION_DIR)/home $(BUILD_DIR)/$(INSTALL_DIR)

copyperf: createdirs
	$(call printInfo,Copying perf/ files to $(INSTALL_DIR)/perf)
	$(EXEC_CP) -r $(APPLICATION_DIR)/perf $(BUILD_DIR)/$(INSTALL_DIR)

copyusr: createdirs
	$(call printInfo,Copying usr/ files to $(BUILD_DIR)/usr)
	$(EXEC_CP) -rL $(APPLICATION_DIR)/usr $(BUILD_DIR)

copyfiles: copybase copyetc copyhome copyperf copyusr

configdocs: copyusr
	echo
	$(call printInfo,Installing documentation files to /usr/share/doc/desktop-configurator)
	$(EXEC_CP) $(APPLICATION_DIR)/doc/* $(BUILD_DIR)/usr/share/doc/desktop-configurator

	$(call printInfo,Compressing changelog / NEWS.txt / README.txt)
	$(EXEC_GZIP) $(BUILD_DIR)/usr/share/doc/desktop-configurator/changelog
	$(EXEC_GZIP) $(BUILD_DIR)/usr/share/doc/desktop-configurator/NEWS.txt
	$(EXEC_GZIP) $(BUILD_DIR)/usr/share/doc/desktop-configurator/README.txt

installutils: copyusr
	echo
	$(call printInfo,Installing utilities to /usr/local)

	$(call printInfo,Creating symbolic links for /usr/local/bin/convert-number)
	$(EXEC_LN) -sT /usr/local/bin/convert-number $(BUILD_DIR)/usr/local/bin/binary
	$(EXEC_LN) -sT /usr/local/bin/convert-number $(BUILD_DIR)/usr/local/bin/decimal
	$(EXEC_LN) -sT /usr/local/bin/convert-number $(BUILD_DIR)/usr/local/bin/hex
	$(EXEC_LN) -sT /usr/local/bin/convert-number $(BUILD_DIR)/usr/local/bin/octal

	$(call printInfo,Creating symbolic links for /usr/local/bin/convert-temp)
	$(EXEC_LN) -sT /usr/local/bin/convert-temp $(BUILD_DIR)/usr/local/bin/celsius
	$(EXEC_LN) -sT /usr/local/bin/convert-temp $(BUILD_DIR)/usr/local/bin/fahrenheit
	$(EXEC_LN) -sT /usr/local/bin/convert-temp $(BUILD_DIR)/usr/local/bin/kelvin

	$(call printInfo,Creating symbolic links for $(INSTALL_DIR) files)
	$(EXEC_LN) -sT $(INSTALL_DIR)/configure-desktop.sh $(BUILD_DIR)/usr/local/sbin/configure-desktop
	$(EXEC_LN) -sT $(INSTALL_DIR)/device-drivers.sh $(BUILD_DIR)/usr/local/sbin/device-drivers
	$(EXEC_LN) -sT $(INSTALL_DIR)/ttf-msclearfonts.sh $(BUILD_DIR)/usr/local/sbin/ttf-msclearfonts

	$(call printInfo,Creating symbolic links for $(INSTALL_DIR)/etc files)
	$(EXEC_LN) -sT $(INSTALL_DIR)/etc/configure-amdgpu.sh $(BUILD_DIR)/usr/local/sbin/configure-amdgpu
	$(EXEC_LN) -sT $(INSTALL_DIR)/etc/configure-fstab.sh $(BUILD_DIR)/usr/local/sbin/configure-fstab
	$(EXEC_LN) -sT $(INSTALL_DIR)/etc/configure-kernel.sh $(BUILD_DIR)/usr/local/sbin/configure-kernel
	$(EXEC_LN) -sT $(INSTALL_DIR)/etc/configure-nvidia.sh $(BUILD_DIR)/usr/local/sbin/configure-nvidia
	$(EXEC_LN) -sT $(INSTALL_DIR)/etc/configure-system.sh $(BUILD_DIR)/usr/local/sbin/configure-system
	$(EXEC_LN) -sT $(INSTALL_DIR)/etc/apt/configure-apt-mirror.sh $(BUILD_DIR)/usr/local/sbin/configure-apt-mirror
	$(EXEC_LN) -sT $(INSTALL_DIR)/etc/default/configure-grub.sh $(BUILD_DIR)/usr/local/sbin/configure-grub
	$(EXEC_LN) -sT $(INSTALL_DIR)/etc/NetworkManager/configure-nm.sh $(BUILD_DIR)/usr/local/sbin/configure-nm
	$(EXEC_LN) -sT $(INSTALL_DIR)/etc/nftables/configure-nftables.sh $(BUILD_DIR)/usr/local/sbin/configure-nftables
	$(EXEC_LN) -sT $(INSTALL_DIR)/etc/nftables/nftables-private.sh $(BUILD_DIR)/usr/local/sbin/nftables-private
	$(EXEC_LN) -sT $(INSTALL_DIR)/etc/nftables/nftables-public.sh $(BUILD_DIR)/usr/local/sbin/nftables-public
	$(EXEC_LN) -sT $(INSTALL_DIR)/etc/samba/configure-samba.sh $(BUILD_DIR)/usr/local/sbin/configure-samba
	$(EXEC_LN) -sT $(INSTALL_DIR)/etc/security/configure-security.sh $(BUILD_DIR)/usr/local/sbin/configure-security
	$(EXEC_LN) -sT $(INSTALL_DIR)/etc/udev/configure-udev.sh $(BUILD_DIR)/usr/local/sbin/configure-udev

	$(call printInfo,Creating symbolic links for $(INSTALL_DIR)/home files)
	$(EXEC_LN) -sT $(INSTALL_DIR)/home/configure-user.sh $(BUILD_DIR)/usr/local/sbin/configure-user

applysecurity: copyfiles configdocs installutils
	echo
	$(call printInfo,Applying security settings to $(INSTALL_DIR))
	$(EXEC_FIND) $(BUILD_DIR)/$(INSTALL_DIR) -type f \( ! -name "*.sh" ! -name "*.tpl" \) -exec $(EXEC_CHMOD) 640 {} +
	$(EXEC_FIND) $(BUILD_DIR)/$(INSTALL_DIR) -type f \( -name "*.sh" -o -name "*.tpl" \) -exec $(EXEC_CHMOD) 750 {} +

	$(call printInfo,Applying security settings to /etc)
	$(EXEC_FIND) $(BUILD_DIR)/etc -type d -exec $(EXEC_CHMOD) 00755 {} +
	$(EXEC_CHMOD) 644 $(BUILD_DIR)/etc/devops/*
	$(EXEC_CHOWN) -R root:root $(BUILD_DIR)/etc

	$(call printInfo,Applying security settings to /usr)
	$(EXEC_FIND) $(BUILD_DIR)/usr -type d -exec $(EXEC_CHMOD) 00755 {} +
	$(EXEC_CHOWN) -R root:root $(BUILD_DIR)/usr

	$(call printInfo,Applying security settings to /usr/share/doc/desktop-configurator)
	$(EXEC_CHMOD) 644 $(BUILD_DIR)/usr/share/doc/desktop-configurator/*

	$(call printInfo,Applying security settings to /usr/local/bin)
	$(EXEC_CHMOD) -R 755 $(BUILD_DIR)/usr/local/bin/*
	$(EXEC_CHOWN) -R --no-dereference root:users $(BUILD_DIR)/usr/local/bin/*

	$(call printInfo,Applying security settings to /usr/local/sbin)
	$(EXEC_CHMOD) 750 $(BUILD_DIR)/usr/local/sbin/*
	$(EXEC_CHOWN) --no-dereference root:sudo $(BUILD_DIR)/usr/local/sbin/*

package: applysecurity
	echo
	$(call printInfo,Installing $(BUILD_DIR)/DEBIAN/control file)
	$(EXEC_CP) $(CURDIR)/DEBIAN/control $(BUILD_DIR)/DEBIAN

	/usr/local/bin/deb-control $(BUILD_DIR)

	$(call printInfo,Installing $(BUILD_DIR)/DEBIAN/conffiles file)
	$(EXEC_CP) $(CURDIR)/DEBIAN/conffiles $(BUILD_DIR)/DEBIAN

	$(call printInfo,Installing $(BUILD_DIR)/DEBIAN/preinst file)
	$(EXEC_CP) $(CURDIR)/DEBIAN/preinst $(BUILD_DIR)/DEBIAN

	$(call printInfo,Generating DEBIAN/md5sums file)
	/usr/local/bin/md5sums $(BUILD_DIR)

	$(call printInfo,Applying security settings to /DEBIAN files)
	$(EXEC_CHMOD) 644 $(BUILD_DIR)/DEBIAN/control $(BUILD_DIR)/DEBIAN/conffiles $(BUILD_DIR)/DEBIAN/md5sums
	$(EXEC_CHMOD) 755 $(BUILD_DIR)/DEBIAN/preinst

	echo
	$(call printInfo,Building $(PKG_ARCHIVE).deb)
	/usr/bin/dpkg-deb -b $(BUILD_DIR)
	$(EXEC_MV) $(TMPDIR)/$(PKG_ARCHIVE).deb $(RELEASE_DIR)

	echo
	$(call printInfo,Generating SHA256SUM and fileinfo.html)
	cd $(RELEASE_DIR) && \
	/usr/bin/sha256sum $(PKG_ARCHIVE).deb > SHA256SUM && \
	/usr/local/bin/venture fileinfo $(PKG_ARCHIVE).deb

	$(EXEC_CHOWN) -R $${SUDO_USER}:$${SUDO_USER} $(RELEASE_DIR)
	$(EXEC_CHMOD) 640 $(RELEASE_DIR)/*

	$(EXEC_RM) -rf $(BUILD_DIR)

printenv:
	echo "  MAKEFILE_LIST: $(MAKEFILE_LIST)"
	echo "         TMPDIR: $(TMPDIR)"
	echo "         CURDIR: $(CURDIR)"
	echo "       PKG_NAME: $(PKG_NAME)"
	echo "        VERSION: $(VERSION)"
	echo "           ARCH: $(ARCH)"
	echo "    PKG_ARCHIVE: $(PKG_ARCHIVE)"
	echo "      BUILD_DIR: $(BUILD_DIR)"
	echo "APPLICATION_DIR: $(APPLICATION_DIR)"
	echo "  UTILITIES_DIR: $(UTILITIES_DIR)"
	echo "    RELEASE_DIR: $(RELEASE_DIR)"
	echo "    INSTALL_DIR: $(INSTALL_DIR)"
	echo
