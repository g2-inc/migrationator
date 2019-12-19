#!/usr/local/bin/zsh
#-
# Copyright (c) 2019 Huntington Ingalls Industries
# Author: Shawn Webb <shawn.webb@hii-tsd.com>
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions
# are met:
# 1. Redistributions of source code must retain the above copyright
#    notice, this list of conditions and the following disclaimer.
# 2. Redistributions in binary form must reproduce the above copyright
#    notice, this list of conditions and the following disclaimer in the
#    documentation and/or other materials provided with the distribution.
#
# THIS SOFTWARE IS PROVIDED BY THE AUTHOR AND CONTRIBUTORS ``AS IS'' AND
# ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED.  IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE LIABLE
# FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
# OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
# HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
# LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
# OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
# SUCH DAMAGE.

_m_sleep=57
declare -A _m_verb_settings

config_set_defaults() {
	return 0
}

config_is_verb_setting() {
	local verb

	verb="${1}"

	if [ "${verb[0,5]}" = "verb:" ]; then
		return 0
	fi

	return 1
}

config_set_value() {
	local name

	set -x

	case "${1}" in
		"sleep")
			_m_sleep=${2}
			;;
		*)
			if config_is_verb_setting "${1}"; then
				name=${1[6,${#1}]}
				_m_verb_settings[${name}]=${2}
				return 0
			fi
			return 1
	esac
	return 0
}

config_get_value() {
	local name

	case "${1}" in
		"sleep")
			echo ${_m_sleep}
			;;
		*)
			if config_is_verb_setting "${1}"; then
				name=${1[6,${#1}]}
				echo ${_m_verb_settings[${name}]}
				return 0
			fi
			return 1
	esac
	return 0
}
