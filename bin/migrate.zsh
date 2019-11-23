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

run_batch() {
	local res
	local users

	users=${1}
	echo ${users} | while read line; do
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
	done

	echo "[+] Exports in this batch initiated. Now waiting for download availability."
	while true; do
		dlready=1
		echo ${users} | while read line; do
			if [ ${dlready} -eq 0 ]; then
				break
			fi

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
			exportinfo=$(${GAM} info export ${matter} ${exportname})
			exportstatus=$(echo ${exportinfo} | \
			    grep '^ status: ' | \
			    awk '{print $2;}')
			case "${exportstatus}" in
				"COMPLETED")
					;;
				*)
					dlready=0
					;;
			esac

			echo "[*] ${acct} status: ${exportstatus}"
			sleep 60
		done

		if [ ${dlready} -eq 1 ]; then
			break
		fi
	done

	echo "[+] Downloads available. Downloading this batch now."

	echo ${users} | while read line; do
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

		mkdir -p ${odir}/${matter}/${acct}

		echo "[+] Downloading ${acct} mail to ${odir}/${matter}/${acct}"

		${GAM} download export ${matter} ${exportname} \
		    targetfolder ${odir}/${matter}/${acct}
		res=${?}
		if [ ${res} -gt 0 ]; then
			return ${res}
		fi
	done
}

main() {
	local acct
	local hasmbox
	local ifile
	local res
	local self

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
		run_batch "$(sed -n ${floor},${ceiling}p ${ifile})"
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
