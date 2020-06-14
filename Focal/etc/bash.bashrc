#
# bash.bashrc - DevOpsBroker configuration file for /etc/bash.bashrc
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
# System-wide Bash shell startup initialization file, executed every time an
# interactive, non-login shell is started (i.e. new Terminal window).
#
# This file is sourced in /etc/profile in order to enable the settings and
# commands found in this file for login shells as well.
# -----------------------------------------------------------------------------
#

# If not running interactively, don't do anything
[ -z "$PS1" ] && return

# Don't put duplicate lines or lines starting with space in the history
# See bash(1) for more options
HISTCONTROL=ignoreboth:erasedups

# Append to the history file, don't overwrite it
shopt -s histappend

# Set history length
HISTSIZE=1000
HISTFILESIZE=2000

# Check the window size after each command and, if necessary, update the values
# of LINES and COLUMNS
shopt -s checkwinsize

# Set variable identifying the chroot you work in (used in the prompt below)
if [ -z "${debian_chroot:-}" ] && [ -r /etc/debian_chroot ]; then
	debian_chroot=$(cat /etc/debian_chroot)
fi

# Set a fancy prompt (colored if Terminal supports it)
case "$TERM" in
	xterm-color|*-256color) color_prompt=yes;;
esac

# Uncomment for a colored prompt, if the terminal has the capability; turned
# off by default to not distract the user: the focus in a terminal window
# should be on the output of commands, not on the prompt
#force_color_prompt=yes

if [ -n "$force_color_prompt" ]; then
	if [ -x /usr/bin/tput ] && tput setaf 1 >&/dev/null; then
		# We have color support; assume it's compliant with Ecma-48 (ISO/IEC-6429).
		# (Lack of such support is extremely rare, and such a case would tend
		# to support setf rather than setaf.)
		color_prompt=yes
	else
		color_prompt=
	fi
fi

if [ "$color_prompt" = yes ]; then
	PS1='${debian_chroot:+($debian_chroot)}\[[1;38;2;114;221;138m\]\u@\h\[[0m\]:\[[1;38;2;159;194;230m\]\w\[[0m\]\$ '
else
	PS1='${debian_chroot:+($debian_chroot)}\u@\h:\w\$ '
fi
unset color_prompt force_color_prompt

# Commented out, don't overwrite xterm -T "title" -n "icontitle" by default.
# If this is an xterm set the title to user@host:dir
#case "$TERM" in
#xterm*|rxvt*)
#    PROMPT_COMMAND='echo -ne "\033]0;${USER}@${HOSTNAME}: ${PWD}\007"'
#    ;;
#*)
#    ;;
#esac

# Enable Bash completion in interactive shells
if ! shopt -oq posix; then
	if [ -f /usr/share/bash-completion/bash_completion ]; then
		. /usr/share/bash-completion/bash_completion
	elif [ -f /etc/bash_completion ]; then
		. /etc/bash_completion
	fi
fi

# sudo hint
if [ ! -e "$HOME/.sudo_as_admin_successful" ] && [ ! -e "$HOME/.hushlogin" ] ; then
	case " $(groups) " in *\ admin\ *|*\ sudo\ *)
		if [ -x /usr/bin/sudo ]; then
			echo 'To run a command as administrator (user "root"), use "sudo <command>".'
			echo 'See "man sudo_root" for details.'
		fi
	esac
fi

# if the command-not-found package is installed, use it
if [ -x /usr/lib/command-not-found -o -x /usr/share/command-not-found/command-not-found ]; then
	function command_not_found_handle {
		# check because c-n-f could've been removed in the meantime
		if [ -x /usr/lib/command-not-found ]; then
			/usr/lib/command-not-found -- "$1"
			return $?
		elif [ -x /usr/share/command-not-found/command-not-found ]; then
			/usr/share/command-not-found/command-not-found -- "$1"
			return $?
		else
			printf "%s: command not found\n" "$1" >&2
			return 127
		fi
	}
fi

# ~~~~~~~~~~~~~~~~~~~~~~~~ DevOpsBroker Configurations ~~~~~~~~~~~~~~~~~~~~~~~~

# Source /etc/devops/ansi.conf
if [ -f /etc/devops/ansi.conf ]; then
	source /etc/devops/ansi.conf
fi

# Source /etc/devops/exec.conf
if [ -f /etc/devops/exec.conf ]; then
	source /etc/devops/exec.conf
fi

# Source /etc/devops/functions.conf
if [ -f /etc/devops/functions.conf ]; then
	source /etc/devops/functions.conf
fi
