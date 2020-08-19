#!/usr/bin/bash

#
# configure-desktop.sh - DevOpsBroker configuration script for Ubuntu 20.04 Desktop
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
# Performs the following configurations:
#   o Configures IPv4 firewall and IPv6 firewall using nftables
#   o Installs all DevOpsBroker system administration and user utilities
#   o Installs a number of useful applications, libraries and utilities
#   o Installs any available proprietary drivers
#   o Configures and optimizes the filesystem
#   o Performs Linux kernel tuning optimizations
#   o Performs general system configuration
#   o Configures the fastest APT sources mirror
#   o Configures and optimizes GRUB
#   o Manages DevOpsBroker configuration files (e.g. ansi.conf)
#   o Tunes the default network interface card
#   o Performs Samba configuration and optimization
#   o Configures systemwide security configuration
#   o Configures the Disk I/O schedulers and tunes each disk independently
#   o Configure systemd-resolved DNS servers
#   o Performs user configuration
#
# Unnstalls the following packages:
#   o irqbalance
#   o libc6-dbg
#
# Useful Linux Command-Line Utilities
# ¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯
# Dynamic real-time view of running processes:
#   o htop
#
# Snapshot view of active processes:
#   o ps
#
# Check Available RAM:
#   o free -h
#
# Report virtual memory statistics (PGPGIN/PGPGOUT):
#   o vmstat -s
#
# View USB Device Tree:
#   o lsusb -tv
#
# View PCI Device Tree:
#   o lspci -tv
#
# View Filesystem Types and Mountpoints:
#   o lsblk -o NAME,FSTYPE,LABEL,SIZE,UUID,MOUNTPOINT
#
# View status of Linux Kernel modules:
#   o lsmod
#
# View all available connection profiles for all network interfaces
#   o nmcli device show
#
# View which devices and handlers are currently active:
#   o cat /proc/bus/input/devices
#
# View every program which is listening on sockets for TCP/UDP traffic:
#   o sudo netstat -tulpn
#
# Scan the 192.168.0.0/24 subnet for every device with an open port 631:
#   o nmap -p T:631 192.168.0.0/24 | grep -B4 open
#
# View shared object dependencies
#   o ldd /usr/bin/glxgears
#
# TODO: Test everything...again!!!
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

# Load /etc/devops/functions-net.conf if FUNC_NET_CONFIG is unset
if [ -z "$FUNC_NET_CONFIG" ] && [ -f /etc/devops/functions-net.conf ]; then
	source /etc/devops/functions-net.conf
fi

${FUNC_NET_CONFIG?"[1;91mCannot load '/etc/devops/functions-net.conf': No such file[0m"}

## Script information
SCRIPT_INFO=( $($EXEC_SCRIPTINFO "$BASH_SOURCE") )
SCRIPT_DIR="${SCRIPT_INFO[0]}"
SCRIPT_EXEC="${SCRIPT_INFO[1]}"

# Display error if not running as root
if [ "$USER" != 'root' ]; then
	printError "$SCRIPT_EXEC" 'Permission denied (you must be root)'
	exit 1
fi

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~ Ubuntu Version Check ~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# Check which version of Ubuntu is installed
DISTRO_INFO="$(/usr/bin/lsb_release -sc)"

# Display error if not running on Ubuntu 20.04 focal
if [ "$DISTRO_INFO" != 'focal' ]; then
	printError "$SCRIPT_EXEC" "Invalid Linux distribution '$DISTRO_INFO'"
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
	PKG_INSTALLED=false

	if [ ! -f "$1" ]; then
		printBanner "Installing $2"
		$EXEC_APT --yes --no-install-recommends install $2
		PKG_INSTALLED=true
		echo
	fi
}

# ¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯
# Function:     uninstallPackage
# Description:  Uninstalls the specified package, if already installed
#
# Parameter $1: The file to check for existence; uninstall if present
# Parameter $2: The name of the package to uninstall
# -----------------------------------------------------------------------------
function uninstallPackage() {
	if [ -f "$1" ]; then
		printBanner "Uninstalling $2"
		$EXEC_APT -y purge $2
		echo
	fi
}

################################## Variables ##################################

## Bash exec variables
EXEC_ADD_APT_REPO=/usr/bin/add-apt-repository

## Variables
DEFAULT_NIC="$(getDefaultNIC)"
IS_AMD=0
PKG_INSTALLED=false

################################### Actions ###################################

# Clear screen only if called from command line
if [ $SHLVL -eq 1 ]; then
	clear
fi

printBox "DevOpsBroker $UBUNTU_RELEASE Configurator" 'true'

# Detect if we are running on an AMD CPU
if [ "$($EXEC_LSCPU | $EXEC_AWK '/Vendor ID:/{ print $3 }')" == 'AuthenticAMD' ]; then
	IS_AMD=1
fi

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ Firewall ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

"$SCRIPT_DIR/etc/nftables/configure-nftables.sh"

#~~~~~~~~~~~~~~~~~~~~~~~~~~~ DevOpsBroker Utilities ~~~~~~~~~~~~~~~~~~~~~~~~~~~

# Install and/or update DevOpsBroker system administration and user utilities
if [ -f "$SCRIPT_DIR"/update-utils.sh ]; then
	"$SCRIPT_DIR"/update-utils.sh
fi

# ~~~~~~~~~~~~~~~~~~~~~~~~~ APT Sources Configuration ~~~~~~~~~~~~~~~~~~~~~~~~~

# Install curl
installPackage '/usr/bin/curl' 'curl'

# Install gawk
installPackage '/usr/bin/gawk' 'gawk'

# Install parallel
installPackage '/usr/bin/parallel' 'parallel'

# Configure /etc/apt/sources.list with configure-apt-mirror.sh script
"$SCRIPT_DIR"/etc/apt/configure-apt-mirror.sh

#~~~~~~~~~~~~~~~~~~~~ Applications / Libraries / Utilities ~~~~~~~~~~~~~~~~~~~~

# Install abcde
installPackage '/usr/bin/abcde' 'abcde'

# Install apparmor-utils
installPackage '/usr/sbin/aa-genprof' 'apparmor-utils'

# Install apt-transport-https
installPackage '/usr/share/doc/apt-transport-https/copyright' 'apt-transport-https'

# Install arp-scan
installPackage '/usr/sbin/arp-scan' 'arp-scan'

# Install aspell
installPackage '/usr/bin/aspell' 'aspell aspell-en'

# Install audacious
installPackage '/usr/bin/audacious' 'audacious'

# Install avahi-daemon
installPackage '/usr/sbin/avahi-daemon' 'avahi-daemon'

# Install ca-certificates
installPackage '/usr/sbin/update-ca-certificates' 'ca-certificates'

# Install dconf-editor
installPackage '/usr/bin/dconf-editor' 'dconf-editor'

# Install debhelper
installPackage '/usr/bin/dh' 'debhelper'

# Install dkms
installPackage '/usr/sbin/dkms' 'dkms'

# Install dnsutils
installPackage '/usr/share/doc/dnsutils/copyright' 'dnsutils'

# Install dos2unix
installPackage '/usr/bin/dos2unix' 'dos2unix'

# Install easytag
installPackage '/usr/bin/easytag' 'easytag'

# Install eject
installPackage '/usr/bin/eject' 'eject'

# Install ethtool
installPackage '/sbin/ethtool' 'ethtool'

# Install exfat
installPackage '/sbin/mkfs.exfat' 'exfat-utils'

# Install ffmpeg
installPackage '/usr/bin/ffmpeg' 'ffmpeg'

# Install fio
installPackage '/usr/bin/fio' 'fio'

# Install flac
installPackage '/usr/bin/flac' 'flac'

# Install flashplugin-installer
installPackage '/usr/share/doc/flashplugin-installer/copyright' 'flashplugin-installer'

# Install gcc
installPackage '/usr/bin/gcc' 'gcc'

# Install gdb
installPackage '/usr/bin/gdb' 'gdb'

# Install gimp
installPackage '/usr/bin/gimp' 'gimp'

# Install git
installPackage '/usr/bin/git' 'git'

# Install gnome-shell-extensions
installPackage '/usr/bin/gnome-session-classic' 'gnome-shell-extensions'

# Install gnome-shell-pomodoro
installPackage '/usr/bin/gnome-pomodoro' 'gnome-shell-pomodoro'

# Install gnome-tweaks
installPackage '/usr/bin/gnome-tweaks' 'gnome-tweaks'

# Install gnome-weather
installPackage '/usr/bin/gnome-weather' 'gnome-weather'

# Install gparted
installPackage '/usr/sbin/gparted' 'gparted'

# Install gstreamer1.0-plugins-good
installPackage '/usr/share/doc/gstreamer1.0-plugins-good/copyright' 'gstreamer1.0-plugins-good'

# Install gstreamer1.0-libav
installPackage '/usr/share/doc/gstreamer1.0-libav/copyright' 'gstreamer1.0-libav'

# Install hardinfo
installPackage '/usr/bin/hardinfo' 'hardinfo'

# Install htop
installPackage '/usr/bin/htop' 'htop'

# Install hwinfo
installPackage '/usr/sbin/hwinfo' 'hwinfo'

# Install imagemagick
installPackage '/usr/bin/convert' 'imagemagick'

# Install inkscape
installPackage '/usr/bin/inkscape' 'inkscape'

# Install ioping
installPackage '/usr/bin/ioping' 'ioping'

# Uninstall irqbalance
uninstallPackage '/usr/sbin/irqbalance' 'irqbalance'

# Install lame
installPackage '/usr/bin/lame' 'lame'

# Install libaio-dev
installPackage '/usr/include/libaio.h' 'libaio-dev'

# Install libc-bin
installPackage '/usr/share/doc/libc-bin/copyright' 'libc-bin'

# Uninstall libc6-dbg
uninstallPackage '/usr/share/doc/libc6-dbg/copyright' 'libc6-dbg'

# Install libcanberra-gtk-module
installPackage '/usr/share/doc/libcanberra-gtk-module/copyright' 'libcanberra-gtk-module'

# Install libgtk-3-dev
installPackage '/usr/include/gtk-3.0/gtk/gtk.h' 'libgtk-3-dev'

# Install libmagic-dev
installPackage '/usr/include/magic.h' 'libmagic-dev'

# Install libpam-modules
installPackage '/etc/security/access.conf' 'libpam-modules'

# Install linux-generic-hwe-20.04
installPackage '/usr/share/doc/linux-generic-hwe-20.04/copyright' 'linux-generic-hwe-20.04'

# Install lm-sensors
installPackage '/usr/bin/sensors' 'lm-sensors'

# Install GTK themes
installPackage '/usr/share/doc/arc-theme/copyright' 'arc-theme'
installPackage '/usr/share/doc/adapta-gtk-theme/copyright' 'adapta-gtk-theme'
installPackage '/usr/share/doc/materia-gtk-theme/copyright' 'materia-gtk-theme'

# Install mesa-utils
installPackage '/usr/bin/glxgears' 'mesa-utils'

# Install mmdblookup
installPackage '/usr/bin/mmdblookup' 'mmdb-bin libmaxminddb0'

# Uninstall mtr-tiny
uninstallPackage '/usr/share/doc/mtr-tiny/copyright' 'mtr-tiny'

# Install mtr
installPackage '/usr/share/doc/mtr/copyright' 'mtr'

# Install nasm
installPackage '/usr/bin/nasm' 'nasm'

# Install net-tools
installPackage '/bin/netstat' 'net-tools'

# Install nmap
installPackage '/usr/bin/nmap' 'nmap'

# Install ntp
installPackage '/usr/sbin/ntpd' 'ntp'

# Install openresolv
#installPackage '/sbin/resolvconf' 'openresolv'

# Install openssh-client
installPackage '/usr/bin/ssh-keygen' 'openssh-client'

# Install ovmf
installPackage '/usr/share/ovmf/OVMF.fd' 'ovmf'

# Install pulseeffects
installPackage '/usr/bin/pulseeffects' 'pulseeffects pulseaudio --install-recommends'

# Install pv
installPackage '/usr/bin/pv' 'pv'

# Install qemu-kvm and qemu-utils
installPackage '/usr/bin/kvm' 'qemu-kvm'
installPackage '/usr/bin/qemu-img' 'qemu-utils'

# Install rng-tools
installPackage '/usr/sbin/rngd' 'rng-tools'

if [ "$PKG_INSTALLED" == 'true' ]; then
	/usr/sbin/rngd -r /dev/urandom
fi

# Install samba
installPackage '/usr/sbin/smbd' 'samba'

# Install smbclient
installPackage '/usr/bin/smbclient' 'smbclient'

# Install speedtest-cli
installPackage '/usr/bin/speedtest-cli' 'speedtest-cli'

# Install sudo
installPackage '/usr/bin/sudo' 'sudo'

# Install sysfsutils
installPackage '/usr/bin/systool' 'sysfsutils'

# Uninstall thermald if running on AMD
if [ $IS_AMD -eq 1 ]; then
	uninstallPackage '/usr/sbin/thermald' 'thermald'
else
	installPackage '/usr/sbin/thermald' 'thermald'
fi

# Install tidy
installPackage '/usr/bin/tidy' 'tidy'

# Install tree
installPackage '/usr/bin/tree' 'tree'

# Install ttf-mscorefonts-installer
if [ ! -f '/usr/share/doc/ttf-mscorefonts-installer/copyright' ]; then
	printBanner 'Installing ttf-mscorefonts-installer'

	$EXEC_WGET -P /tmp http://ftp.debian.org/debian/pool/contrib/m/msttcorefonts/ttf-mscorefonts-installer_3.8_all.deb
	$EXEC_APT -y install /tmp/ttf-mscorefonts-installer_3.8_all.deb
	$EXEC_RM /tmp/ttf-mscorefonts-installer_3.8_all.deb
	echo

	printInfo 'Updating the font cache'
	/usr/bin/fc-cache -f -v
	echo
fi

# Install ubuntu-wallpapers
installPackage '/usr/share/backgrounds/contest/xenial.xml' 'ubuntu-wallpapers-xenial'
installPackage '/usr/share/backgrounds/contest/bionic.xml' 'ubuntu-wallpapers-bionic'

# Uninstall vim-tiny
uninstallPackage '/usr/bin/vim.tiny' 'vim-tiny'

# Install vim
installPackage '/usr/bin/vim.basic' 'vim'

# Install vlc
installPackage '/usr/share/applications/vlc.desktop' 'vlc'

# Install whois
installPackage '/usr/bin/whois' 'whois'

# Install whoopsie
installPackage '/usr/bin/whoopsie' 'whoopsie'

# Install xclip
installPackage '/usr/bin/xclip' 'xclip'

# Install yad
installPackage '/usr/bin/yad' 'yad'

# ~~~~~~~~~~~~~~~~~~~~~~~~~ System/User Configuration ~~~~~~~~~~~~~~~~~~~~~~~~~

#
# Device Driver Installation
#

"$SCRIPT_DIR"/device-drivers.sh

#
# Filesystem Configuration
#

"$SCRIPT_DIR"/etc/configure-fstab.sh

#
# Linux Kernel Tuning
#

"$SCRIPT_DIR"/etc/configure-kernel.sh

#
# General System Configuration
#

"$SCRIPT_DIR"/etc/configure-system.sh

#
# GRUB Configuration
#

"$SCRIPT_DIR"/etc/default/configure-grub.sh

#
# NetworkManager Configuration
#

"$SCRIPT_DIR"/etc/NetworkManager/configure-nm.sh $DEFAULT_NIC

#
# Samba Configuration
#

"$SCRIPT_DIR"/etc/samba/configure-samba.sh $DEFAULT_NIC

#
# Systemwide Security Configuration
#

"$SCRIPT_DIR"/etc/security/configure-security.sh

#
# Udev Configuration
#

"$SCRIPT_DIR"/etc/udev/configure-udev.sh

#
# User Configuration
#

"$SCRIPT_DIR"/home/configure-user.sh $SUDO_USER

"$SCRIPT_DIR"/home/configure-cache.sh $SUDO_USER

#
# Upgrade Ubuntu
#

today=$($EXEC_DATE -I)
if [ ! -f /etc/devops/last-update ] || [ $($EXEC_CAT /etc/devops/last-update) != $today ]; then
	/usr/local/sbin/pms upgrade
fi

echo 'Done!'
echo

exit 0
