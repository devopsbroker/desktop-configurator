#!/usr/bin/bash

#
# sysctl.conf.tpl - DevOpsBroker script for generating /etc/sysctl.conf configuration
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
# Configuration file for setting system variables. See the /etc/sysctl.d/
# directory for additional system variable configuration files.
#
# See sysctl.conf(5) and sysctl(8) for more information.
#
# Protects from the following attacks:
#   o SYN Flood Attack
#   o TCP Time-Wait Attack
#   o Source IP Address Spoofing
#   o MITM Attacks
#   o Bad Error Messages
#
# Every kernel parameter that can be tuned specifically for your machine is
# dynamically calculated based upon your machine configuration, network
# interface, and Internet connection speed.
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
EXEC_NETTUNER=/usr/local/bin/nettuner
EXEC_SCHEDTUNER=/usr/local/sbin/schedtuner

## Options
NIC="${1:-}"

## Variables
export TMPDIR=${TMPDIR:-'/tmp'}
YEAR=$($EXEC_DATE +'%Y')
IS_VM_GUEST=0
SCHED_TUNING=''
SOMAXCONN=0
TCP_FRTO=0
TCP_MAX_ORPHANS=0
TCP_MAX_TW_BUCKETS=0

declare -a nicList=()

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ OPTION Parsing ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

if [ -z "$NIC" ]; then

	# Get default NIC if not present on command-line
	NIC="$(getDefaultNIC)"

else
	# Display error if network interface parameter is invalid
	if [ ! -L /sys/class/net/$NIC ]; then
		printError "$SCRIPT_EXEC" "Cannot access '$NIC': No such network interface"
		echo
		printUsage "$SCRIPT_EXEC ${gold}[NIC]"

		exit 1
	fi
fi

# Exit if network interface is a virtual network device (i.e. bridge, tap, etc)
if [[ "$($EXEC_READLINK /sys/class/net/$NIC)" == *"/devices/virtual/"* ]]; then
	printInfo "Network interface '$NIC' is virtual"
	printInfo 'Exiting'

	exit 0
fi

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~ General Information ~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# Total amount of RAM available
RAM_TOTAL=$(getRamTotal)

# Amount of RAM available in GB
RAM_GB=$[ ($RAM_TOTAL + 1048575) / 1048576 ]

# Detect whether Ubuntu Server is running as a guest in a virtual machine
detectVirtualization

if [ $IS_VM_GUEST -eq 0 ]; then

	SCHED_TUNING="$($EXEC_SCHEDTUNER)"

else
	CPU_MAX_FREQ=''
	MEM_BUS_SPEED=''

	while [ -z "$CPU_MAX_FREQ" ]; do
		read -p 'What is the CPU maximum frequency?: ' CPU_MAX_FREQ

		if [[ ! "$CPU_MAX_FREQ" =~ ^[0-9]+$ ]]; then
			CPU_MAX_FREQ=''
		fi
	done

	while [ -z "$MEM_BUS_SPEED" ]; do
		read -p 'What is the memory bus speed?: ' MEM_BUS_SPEED

		if [[ ! "$MEM_BUS_SPEED" =~ ^[0-9]+$ ]]; then
			MEM_BUS_SPEED=''
		fi
	done

	SCHED_TUNING="$($EXEC_SCHEDTUNER -f $CPU_MAX_FREQ -m $MEM_BUS_SPEED)"
fi

# --------------------------- Filesystem Information --------------------------

# Global Maximum Number Simultaneous Open Files
FS_FILE_MAX=$[ $RAM_TOTAL / 10 ]

# ---------------------------- Network Information ----------------------------

SOMAXCONN=$[ $RAM_GB * 128 ]
TCP_MAX_ORPHANS=$[ $RAM_GB * 64 ]
TCP_MAX_TW_BUCKETS=$[ $RAM_GB * 16384 ]

nicList=$(/usr/sbin/ip -br link show | /usr/bin/awk '{print $1}')

# Check if we have a Wi-Fi network device
for nicDevice in "${nicList[@]}"; do
	if [[ $nicDevice == w* ]]; then
		TCP_FRTO=2
		break;
	fi
done

# ------------------------- Virtual Memory Information ------------------------

# Configure VM Dirty Ratio / VM Dirty Background Ratio / VM VFS Cache Pressure
case $RAM_GB in
[1-2])
	VM_DIRTY_RATIO=8
	VM_DIRTY_BG_RATIO=4
	VM_VFS_CACHE_PRESSURE=150
	;;
[3-4])
	VM_DIRTY_RATIO=6
	VM_DIRTY_BG_RATIO=3
	VM_VFS_CACHE_PRESSURE=125
	;;
[5-6])
	VM_DIRTY_RATIO=5
	VM_DIRTY_BG_RATIO=3
	VM_VFS_CACHE_PRESSURE=100
	;;
[7-8])
	VM_DIRTY_RATIO=4
	VM_DIRTY_BG_RATIO=2
	VM_VFS_CACHE_PRESSURE=90
	;;
[9-12])
	VM_DIRTY_RATIO=3
	VM_DIRTY_BG_RATIO=2
	VM_VFS_CACHE_PRESSURE=80
	;;
*)
	VM_DIRTY_RATIO=2
	VM_DIRTY_BG_RATIO=1
	VM_VFS_CACHE_PRESSURE=70
	;;
esac

# Configure VM Minimum Free Memory (1% of physical RAM)
VM_MIN_FREE_KB=$[ $RAM_TOTAL / 100 ]

## Template
/bin/cat << EOF
#
# sysctl.conf - DevOpsBroker Linux kernel tuning configuration file
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

#
# Linux Kernel Tuning Configuration
# ¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯

# Set the hostname of the machine
#kernel.hostname = covfefe

# Set the domain name of the host
#kernel.domainname = example.com

# Set Default Kernel Log Levels
kernel.printk = 4 4 1 7

# Enable PID Append To Kernel Core Dumps
kernel.core_uses_pid = 1

# Disable NMI Watchdog
kernel.nmi_watchdog = 0

# Set the kernel panic timeout to autoreboot
kernel.panic = 10

# Limit perf cpu time to 5%
kernel.perf_cpu_time_max_percent = 5

# Increase the PID_MAX limit
kernel.pid_max = 1048576

# Kernel Task Scheduler Optimizations
$SCHED_TUNING

# Disable Magic SysRq Key
kernel.sysrq = 0

#
# Filesystem Kernel Tuning Configuration
# ¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯

# Optimize Global Maximum Number Simultaneous Open Files
fs.file-max = $FS_FILE_MAX

#
# Network Kernel Tuning Configuration
# ¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯

# Set Default Queuing Discipline to Fair/Flow Queueing + Codel
net.core.default_qdisc = fq_codel

# Optimize Maximum Amount of Option Memory Buffers
net.core.optmem_max = 32768

# Optimize Connection Backlog
net.core.somaxconn = $SOMAXCONN

# Do not accept source routed packets
net.ipv4.conf.all.accept_source_route = 0
net.ipv6.conf.all.accept_source_route = 0
net.ipv4.conf.default.accept_source_route = 0
net.ipv6.conf.default.accept_source_route = 0

# Do not accept ICMP REDIRECT Messages
net.ipv4.conf.all.accept_redirects = 0
net.ipv6.conf.all.accept_redirects = 0
net.ipv4.conf.default.accept_redirects = 0
net.ipv6.conf.default.accept_redirects = 0

# Disable logging packets with impossible addresses
net.ipv4.conf.all.log_martians = 0
net.ipv4.conf.default.log_martians = 0

# Enable Source Address Verification
net.ipv4.conf.all.rp_filter = 1
net.ipv4.conf.default.rp_filter = 1

# Do not send ICMP REDIRECT Messages
net.ipv4.conf.all.send_redirects = 0
net.ipv4.conf.default.send_redirects = 0

# Allow ICMP ECHO Requests (Ping)
net.ipv4.icmp_echo_ignore_all = 0

# Drop BROADCAST/MULTICAST ICMP ECHO Requests
net.ipv4.icmp_echo_ignore_broadcasts = 1

# Ignore bogus ICMP error responses
net.ipv4.icmp_ignore_bogus_error_responses = 1

# Limit the number of ICMP packets sent per second
net.ipv4.icmp_msgs_per_sec = 100

# Disable IP Forwarding
net.ipv4.ip_forward = 0
net.ipv4.conf.all.forwarding = 0
net.ipv6.conf.all.forwarding = 0
net.ipv4.conf.default.forwarding = 0
net.ipv6.conf.default.forwarding = 0

# Enable Path MTU Discovery if using Jumbo Frames
net.ipv4.ip_no_pmtu_disc = 1

# Increase the total port range for both TCP and UDP connections
net.ipv4.ip_local_port_range = 1500 65001

# Divide socket receive buffer space evenly between TCP window and application
net.ipv4.tcp_adv_win_scale = 1

# Use TCP-BBR Congestion Control Algorithm
net.ipv4.tcp_congestion_control = bbr

# Enable TCP Explicit Congestion Notification (ECN)
net.ipv4.tcp_ecn = 1

# Enable TCP Fast Open (TFO)
net.ipv4.tcp_fastopen = 3

# Optimize TCP FIN Timeout
net.ipv4.tcp_fin_timeout = 20

# Set F-RTO enhanced recovery algorithm based on wireless network presence
net.ipv4.tcp_frto = $TCP_FRTO
net.ipv4.tcp_frto_response=0

# Optimize TCP Keepalive (Detect dead connections after 120s)
net.ipv4.tcp_keepalive_time = 60
net.ipv4.tcp_keepalive_intvl = 10
net.ipv4.tcp_keepalive_probes = 6

# Enable TCP Low Latency
net.ipv4.tcp_low_latency = 1

# Optimize TCP Max Orphans and TCP Max TIME_WAIT Buckets
net.ipv4.tcp_max_orphans = $TCP_MAX_ORPHANS
net.ipv4.tcp_max_tw_buckets = $TCP_MAX_TW_BUCKETS

# Disable TCP Receive Buffer Auto-Tuning
net.ipv4.tcp_moderate_rcvbuf = 0

# Controls TCP Packetization-Layer Path MTU Discovery
net.ipv4.tcp_mtu_probing = 1

# Disable TCP Metrics Cache
net.ipv4.tcp_no_metrics_save = 1

# How may times to retry before killing TCP connection, closed by our side
net.ipv4.tcp_orphan_retries = 1

# Enable TCP Time-Wait Attack Protection
net.ipv4.tcp_rfc1337 = 1

# Enable TCP Select Acknowledgments
net.ipv4.tcp_sack = 1
net.ipv4.tcp_dsack = 1
net.ipv4.tcp_fack = 1

# Disable TCP Slow Start After Idle
net.ipv4.tcp_slow_start_after_idle = 0

# Enable SYN Flood Attack Protection
net.ipv4.tcp_max_syn_backlog = 1024
net.ipv4.tcp_synack_retries = 2
net.ipv4.tcp_syncookies = 1

# Optimize TCP SYN Retries
net.ipv4.tcp_syn_retries = 2

# Disable IPv4 TCP Timestamps
net.ipv4.tcp_timestamps = 0

# Enable TCP TIME_WAIT Socket Reuse
net.ipv4.tcp_tw_reuse = 1

# Enable TCP Window Scaling
net.ipv4.tcp_window_scaling = 1

# Set the IPv4 Route Minimum PMTU
net.ipv4.route.min_pmtu = 552

# Set the IPv4 Minimum Advertised MSS
net.ipv4.route.min_adv_mss = 512

#
# Virtual Memory Kernel Tuning Configuration
# ¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯

# Optimize VM Dirty Ratio
vm.dirty_ratio = $VM_DIRTY_RATIO

# Optimize VM Dirty Background Ratio
vm.dirty_background_ratio = $VM_DIRTY_BG_RATIO

# Optimize VM Minimum Free Memory
vm.min_free_kbytes = $VM_MIN_FREE_KB

# Do not allow Virtual Memory overcommit
vm.overcommit_memory = 2
vm.overcommit_ratio = 100

# Do not panic on Out-of-Memory condition
vm.panic_on_oom = 0

# Optimize VM Swappiness
vm.swappiness = 10

# Optimize VM VFS Cache Pressure
vm.vfs_cache_pressure = $VM_VFS_CACHE_PRESSURE

EOF

exit 0
