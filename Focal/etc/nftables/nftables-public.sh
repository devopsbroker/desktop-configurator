#!/usr/bin/bash

#
# nftables-public.sh - DevOpsBroker nftables public network firewall script
#
# Copyright (C) 2020 Edward Smith <edwardsmith@devopsbroker.org>
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
# Developed on Ubuntu 20.04 LTS running kernel.osrelease = 5.4.0-37
#
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

## Options
NIC="${1:-}"

## Variables
YEAR=$($EXEC_DATE +'%Y')
DHCPv6_MULTI_ADDR='ff02::1:2'

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

################################### Actions ###################################

# Clear screen only if called from command line
#if [ $SHLVL -eq 1 ]; then
#	clear
#fi
#
#printBox "DevOpsBroker $UBUNTU_RELEASE nftables Public Configurator" 'true'
#
#echo "${bold}Network Interface:   ${green}$NIC"
#echo "${white}IPv4 Address:        ${green}$IPv4_ADDRESS"
#echo "${white}IPv4 Gateway:        ${green}$IPv4_GATEWAY"
#echo "${white}IPv4 Subnet:         ${green}$IPv4_SUBNET"
#echo
#echo "${white}IPv6 Global Address: ${green}$IPv6_ADDRESS_GLOBAL"
#echo "${white}IPv6 Local Address:  ${green}$IPv6_ADDRESS_LOCAL"
#echo "${white}IPv6 Gateway:        ${green}$IPv6_GATEWAY"
#echo "${white}IPv6 Global Subnet:  ${green}$IPv6_SUBNET_GLOBAL"
#echo "${white}IPv6 Local Subnet:   ${green}$IPv6_SUBNET_LOCAL"
#echo "${reset}"

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ Template ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

/usr/bin/cat << EOF
#!/usr/sbin/nft -f

#
# ${NIC}-public.nft - DevOpsBroker nftables public network firewall script
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

flush ruleset

#
# TCP Ports Set Configuration
# ¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯

define TCP_CLIENT_PORTS = {
  53,                       # DNS
  80,                       # HTTP
  443                       # HTTPS
}

#define TCP_SERVICE_PORTS = {
#
#}

#
# UDP Ports Set Configuration
# ¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯

define UDP_CLIENT_PORTS = {
  53,                       # DNS
  123                       # NTP
}

#define UDP_SERVICE_PORTS = {
#
#}

#
# IPv4 nftables Configuration
# ¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯

table ip ipv4-firewall {

  chain input-dispatcher {
	type filter hook input priority 0;

	# Drop invalid packets
	ct state invalid drop

	# Allow loopback interface
	iifname ${NIC} jump ${NIC}-input
	iifname lo accept

	# Reject traffic from all other interfaces
	log level info prefix "[IPv4 INPUT BLOCK] " reject with icmp type port-unreachable
  }

  chain ${NIC}-input {
	# Filter by protocol
	ip protocol tcp jump ${NIC}-input-tcp
	ip protocol udp jump ${NIC}-input-udp
	ip protocol icmp jump ${NIC}-input-icmp

	# Reject all other traffic
	log level info prefix "[IPv4 ${NIC} BLOCK] " reject with icmp type port-unreachable
  }

  chain ${NIC}-input-tcp {
	tcp sport \$TCP_CLIENT_PORTS accept
#	tcp dport \$TCP_SERVICE_PORTS accept
	log level info prefix "[IPv4 TCP BLOCK] " reject with tcp reset
  }

  chain ${NIC}-input-udp {
	udp sport \$UDP_CLIENT_PORTS accept
#	udp dport \$UDP_SERVICE_PORTS accept
	udp sport 67 udp dport 68 accept
	log level info prefix "[IPv4 UDP BLOCK] " reject with icmp type port-unreachable
  }

  chain ${NIC}-input-icmp {
	icmp type { destination-unreachable, parameter-problem, echo-reply, time-exceeded } accept
	icmp type echo-request limit rate 10/second accept
	log level info prefix "[IPv4 ICMP BLOCK] " drop
  }

  chain forwarding {
	type filter hook forward priority 0; policy drop;
  }

  chain output-dispatcher {
	type filter hook output priority 0;

	# Drop invalid packets
	ct state invalid drop

	# Allow loopback interface
	oifname ${NIC} jump ${NIC}-output
	oifname lo accept

	# Reject traffic from all other interfaces
	log level info prefix "[IPv4 OUTPUT BLOCK] " reject with icmp type port-unreachable
  }

  chain ${NIC}-output {
	# Filter by protocol
	ip protocol tcp jump ${NIC}-output-tcp
	ip protocol udp jump ${NIC}-output-udp
	ip protocol icmp accept

	# Reject all other traffic
	log level info prefix "[IPv4 ${NIC} BLOCK] " reject with icmp type port-unreachable
  }

  chain ${NIC}-output-tcp {
	tcp dport \$TCP_CLIENT_PORTS accept
#	tcp sport \$TCP_SERVICE_PORTS accept
	log level info prefix "[IPv4 TCP BLOCK] " reject with tcp reset
  }

  chain ${NIC}-output-udp {
	udp dport \$UDP_CLIENT_PORTS accept
#	udp sport \$UDP_SERVICE_PORTS accept
	udp sport 68 udp dport 67 accept
	log level info prefix "[IPv4 UDP BLOCK] " reject with icmp type port-unreachable
  }

}

#
# IPv6 nftables Configuration
# ¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯

table ip6 ipv6-firewall {

  chain input-dispatcher {
	type filter hook input priority 0;

	# Drop invalid packets
	ct state invalid drop

	# Allow loopback interface
	iifname ${NIC} jump ${NIC}-input
	iifname lo accept

	# Reject traffic from all other interfaces
	log level info prefix "[IPv6 INPUT BLOCK] " reject with icmpv6 type port-unreachable
  }

  chain ${NIC}-input {
	# Filter by protocol
	meta l4proto tcp jump ${NIC}-input-tcp
	meta l4proto udp jump ${NIC}-input-udp
	meta l4proto icmpv6 jump ${NIC}-input-icmpv6

	# Reject all other traffic
	log level info prefix "[IPv6 ${NIC} BLOCK] " reject with icmpv6 type port-unreachable
  }

  chain ${NIC}-input-tcp {
	tcp sport \$TCP_CLIENT_PORTS accept
#	tcp dport \$TCP_SERVICE_PORTS accept
	log level info prefix "[IPv6 TCP BLOCK] " reject with tcp reset
  }

  chain ${NIC}-input-udp {
	udp sport \$UDP_CLIENT_PORTS accept
#	udp dport \$UDP_SERVICE_PORTS accept
	udp sport 547 udp dport 546 accept
	log level info prefix "[IPv6 UDP BLOCK] " reject with icmpv6 type port-unreachable
  }

  chain ${NIC}-input-icmpv6 {
	icmpv6 type { nd-neighbor-solicit, nd-neighbor-advert, mld-listener-query, destination-unreachable, packet-too-big, parameter-problem, echo-reply, time-exceeded } accept
	icmpv6 type echo-request limit rate 10/second accept
	log level info prefix "[IPv6 ICMPv6 BLOCK] " drop
  }

  chain forwarding {
	type filter hook forward priority 0; policy drop;
  }

  chain output-dispatcher {
	type filter hook output priority 0;

	# Drop invalid packets
	ct state invalid drop

	# Allow loopback interface
	oifname ${NIC} jump ${NIC}-output
	oifname lo accept

	# Reject traffic from all other interfaces
	log level info prefix "[IPv6 OUTPUT BLOCK] " reject with icmpv6 type port-unreachable
  }

  chain ${NIC}-output {
	# Filter by protocol
	meta l4proto tcp jump ${NIC}-output-tcp
	meta l4proto udp jump ${NIC}-output-udp
	meta l4proto icmpv6 accept

	# Reject all other traffic
	log level info prefix "[IPv6 ${NIC} BLOCK] " reject with icmpv6 type port-unreachable
  }

  chain ${NIC}-output-tcp {
	tcp dport \$TCP_CLIENT_PORTS accept
#	tcp sport \$TCP_SERVICE_PORTS accept
	log level info prefix "[IPv6 TCP BLOCK] " reject with tcp reset
  }

  chain ${NIC}-output-udp {
	udp dport \$UDP_CLIENT_PORTS accept
#	udp sport \$UDP_SERVICE_PORTS accept
	udp sport 546 udp dport 547 ip6 daddr ${DHCPv6_MULTI_ADDR} accept
	log level info prefix "[IPv6 UDP BLOCK] " reject with icmpv6 type port-unreachable
  }
}

EOF
