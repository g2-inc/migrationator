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

matter="migration-$(date '+%F_%T')"
GAM="${HOME}/projects/GAM/src/gam.py"

main() {
	local acct
	local hasmbox
	local ifile
	local res
	local self

	self=${0}
	shift

	while getopts 'i:' o; do
		case "${o}" in
			i)
				ifile="${OPTARG}"
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

	while read line; do
		acct=$(echo ${line} | awk -F ',' '{print $1;}')
		hasmbox=$(echo ${line} | awk -F ',' '{print $2;}')
		haslicense=$(echo ${line} | grep -Fi "google vault")
		if [ ${hasmbox} = "False" ]; then
			continue
		fi
		if [ -z "${haslicense}" ]; then
			continue
		fi

		echo "[*] Initiating mail export of account ${acct}"

		exportname="export-mail-${acct:gs/@/_}"
		${GAM} create export \
		    format pst \
		    name ${exportname} \
		    matter ${matter} corpus mail \
		    accounts ${acct}
		res=${?}
		if [ ${res} -gt 0 ]; then
			echo "    [-] Unable to initiate mail vault export of ${acct}"
			return 1
		fi

		echo "[*] Sleeping for 60 seconds due to API quota"
		sleep 60
	done < ${ifile}

	while read line; do
		acct=$(echo ${line} | awk -F ',' '{print $1;}')
		hasmbox=$(echo ${line} | awk -F ',' '{print $2;}')
		haslicense=$(echo ${line} | grep -Fi "google vault")
		if [ ${hasmbox} = "False" ]; then
			continue
		fi
		if [ -z "${haslicense}" ]; then
			continue
		fi

		exportname="export-mail-${acct:gs/@/_}"
		exportstatus=$(${GAM} info export ${matter} ${exportname} | \
		    grep '^status:' | awk '{print $2;}')
		echo "[*] ${acct} export status: ${exportstatus}"

		echo "[*] Sleeping for 60 seconds due to API quota"
		sleep 60
	done < ${ifile}

	${GAM} update matter ${matter} action close
	${GAM} update matter ${matter} action delete

	return 0
}

main ${0} $*
exit ${?}
