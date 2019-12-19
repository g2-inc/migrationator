#!/usr/bin/env zsh
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

GAM="GAM"

matter="migration-$(date '+%F_%T')"

get_topdir() {
	local self

	self=${1}

	echo $(realpath $(dirname ${self})/..)
	return ${?}
}

TOPDIR=$(get_topdir ${0})

. ${TOPDIR}/lib/migrationator/config.zsh
. ${TOPDIR}/lib/migrationator/drive.zsh
. ${TOPDIR}/lib/migrationator/email.zsh
. ${TOPDIR}/lib/migrationator/util.zsh
. ${TOPDIR}/lib/migrationator/log.zsh

main() {
	local noclean
	local o
	local res
	local self
	local verb

	self=${1}
	shift

	config_set_defaults

	while getopts 'Cvs:' o; do
		case "${o}" in
			C)
				noclean="-C"
				;;
			s)
				config_set_value "sleep" ${OPTARG}
				;;
			v)
				inc_verbosity
				;;
		esac
	done

	verb=${@[${OPTIND}]}
	[ -z "${verb}" ] && usage ${self}
	shift ${OPTIND}
	sanity_checks ${self} ${verb} || exit 1

	trap "cleanup ${noclean}" SIGINT

	# We passed sanity checks, so we know this verb is supported.
	. ${TOPDIR}/lib/migrationator/verbs/${verb}.zsh
	$(echo ${verb}_need_matter)
	if [ ${?} -eq 1 ]; then
		${GAM} create vaultmatter \
		    name ${matter} \
		    description "Vault export"
		res=${?}
		if [ ${res} -gt 0 ]; then
			return ${res}
		fi

		log_debug_arg "[*] Sleeping for $(config_get_value sleep) seconds due to API quota."
		sleep $(config_get_value sleep)
	fi
	$(echo ${verb}_run) $@
	res=${?}

	cleanup ${noclean}

	return ${res}
}

main ${0} $*
exit ${?}
