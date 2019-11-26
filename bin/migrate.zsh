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

GAM="${HOME}/projects/GAM/src/gam.py"

batchstep=15
matter="migration-$(date '+%F_%T')"
odir="/tank/export"

get_topdir() {
	local self

	self=${1}

	echo $(realpath $(dirname ${self}))
	return ${?}
}

TOPDIR=$(get_topdir ${0})

. ${TOPDIR}/../lib/email.zsh

main() {
	local acct
	local hasmbox
	local ifile
	local res
	local self
	local users

	self=${0}
	shift

	while getopts 'i:o:' o; do
		case "${o}" in
			i)
				ifile="${OPTARG}"
				;;
			o)
				odir="${OPTARG}"
				;;
			*)
				;;
		esac
	done

	if [ ! -f "${ifile}" ]; then
		echo "Please specify the input file with -i"
		exit 1
	fi

	${GAM} create vaultmatter \
	    name ${matter} \
	    description "Vault export"
	res=${?}
	if [ ${res} -gt 0 ]; then
		return ${res}
	fi

	echo "[*] Sleeping for 60 seconds to allow google to catch up."
	sleep 60

	mkdir -p ${odir}/${matter}

	naccounts=$(wc -l ${ifile} | awk '{print $1;}')
	for ((i=1; ${i} < ${naccounts}; i+=${batchstep})); do
		floor=${i}
		ceiling=$((${floor} + ${batchstep} - 1))
		echo "==== $((${floor} / ${batchstep})) : $(date '+%F %T') ===="
		users=$(sed -n ${floor},${ceiling}p ${ifile})
		email_init_batch "${users}"
		res=${?}
		if [ ${res} -gt 0 ]; then
			break
		fi
		email_execute_batch "${users}"
		res=${?}
		if [ ${res} -gt 0 ]; then
			break
		fi
		email_download_batch "${users}"
		res=${?}
		if [ ${res} -gt 0 ]; then
			break
		fi
	done

	${GAM} update matter ${matter} action close
	${GAM} update matter ${matter} action delete

	return ${res}
}

main ${0} $*
exit ${?}
